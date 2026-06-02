# frozen_string_literal: true

# Tests for NfsStore::Manage::Filesystem.clean_path
#
# Purpose
# -------
# `Filesystem.clean_path` is the chokepoint used to normalise every user-supplied
# path that eventually contributes to a filesystem location before any file is
# read, written, moved or streamed via `send_file`. It is invoked from:
#   * NfsStore::Upload.find_upload                  (upload `relative_path`)
#   * NfsStore::HandlesContainerFile#clean_path     (before_validation on rows)
#   * NfsStore::MoveAndRename                       (user-supplied new_path)
#   * NfsStore::Archive::Mounter                    (archive sub-paths)
#   * NfsStore::Manage::ContainerFile               (path resolution)
#   * Filesystem.nfs_store_path                     (final assembled path)
#
# Previously there were no direct unit tests for this method. This file adds:
#
#   1. Characterisation tests covering the documented/observed behaviour
#      (blank/`.`/trailing-slash/lexical normalisation). These should pass on
#      the existing code.
#
#   2. Path-traversal & absolute-path tests that demonstrate the current code
#      silently normalises but does **not** reject `..` segments or leading `/`.
#      These tests are intentionally failing on the current implementation and
#      are the red phase of TDD work to harden the filestore against path
#      traversal attacks (no GitHub issue — security hardening).

require 'rails_helper'

RSpec.describe NfsStore::Manage::Filesystem, type: :model do
  describe '.clean_path' do
    # -------------------------------------------------------------------
    # Characterisation: behaviour that must remain unchanged
    # -------------------------------------------------------------------
    context 'when given blank or no-op input' do
      it 'returns nil for nil' do
        expect(described_class.clean_path(nil)).to be_nil
      end

      it 'returns nil for an empty string' do
        expect(described_class.clean_path('')).to be_nil
      end

      it 'returns nil for the current-directory marker "."' do
        expect(described_class.clean_path('.')).to be_nil
      end
    end

    context 'when given a benign relative path' do
      it 'returns a simple single segment unchanged' do
        expect(described_class.clean_path('reports')).to eq('reports')
      end

      it 'returns a nested path unchanged' do
        expect(described_class.clean_path('reports/2024/q1')).to eq('reports/2024/q1')
      end

      it 'collapses interior "./" segments' do
        expect(described_class.clean_path('reports/./2024')).to eq('reports/2024')
      end

      it 'collapses interior ".." segments that remain within the relative root' do
        expect(described_class.clean_path('reports/2024/../2025')).to eq('reports/2025')
      end

      it 'strips a single trailing slash' do
        # Pathname#cleanpath collapses trailing slashes
        expect(described_class.clean_path('reports/')).to eq('reports')
      end
    end

    # -------------------------------------------------------------------
    # SECURITY (RED): inputs that must be rejected to prevent traversal
    # outside the assembled container root before send_file.
    # -------------------------------------------------------------------
    #
    # These cases currently pass through clean_path with only lexical
    # normalisation, so the resulting string still carries an escape
    # sequence (leading `..`) or an absolute prefix. When that value is
    # subsequently fed into `File.join(parts) -> Pathname#cleanpath` by
    # Filesystem.nfs_store_path, the final filesystem path can escape the
    # container's directory.
    #
    # The expected behaviour after hardening is that clean_path raises
    # FsException::Action for any of these inputs (or another
    # explicit rejection mechanism — adjust the matcher when the green
    # phase chooses the exact contract).

    context 'when given a path that escapes the relative root (SECURITY)' do
      it 'rejects a leading "../" segment' do
        expect { described_class.clean_path('../etc/passwd') }
          .to raise_error(FsException::Action)
      end

      it 'rejects "../" alone' do
        expect { described_class.clean_path('..') }
          .to raise_error(FsException::Action)
      end

      it 'rejects a deeper traversal sequence' do
        expect { described_class.clean_path('../../../etc/passwd') }
          .to raise_error(FsException::Action)
      end

      it 'rejects a path that collapses to a leading ".."' do
        # "foo/../../bar" -> Pathname#cleanpath -> "../bar"
        expect { described_class.clean_path('foo/../../bar') }
          .to raise_error(FsException::Action)
      end
    end

    context 'when given an absolute path (SECURITY)' do
      it 'rejects a Unix-style absolute path' do
        expect { described_class.clean_path('/etc/passwd') }
          .to raise_error(FsException::Action)
      end

      it 'rejects an absolute path that points inside the nfs root' do
        # Even paths that "look" legitimate must not bypass the
        # container-relative join logic.
        expect { described_class.clean_path('/var/nfs_store/anything') }
          .to raise_error(FsException::Action)
      end
    end

    context 'when given a path containing a NUL byte (SECURITY)' do
      it 'rejects embedded NUL bytes' do
        expect { described_class.clean_path("reports\x00/safe") }
          .to raise_error(FsException::Action)
      end
    end
  end

  # -------------------------------------------------------------------
  # REGRESSION PROOF-OF-CONCEPT (SECURITY)
  # -------------------------------------------------------------------
  #
  # These specs originally demonstrated, end-to-end, that the
  # path-assembly primitive used throughout NfsStore
  # (`File.join(container_root, attacker_part, ...) -> Pathname#cleanpath`)
  # collapsed traversal sequences AFTER joining them with the container
  # root, yielding an absolute filesystem path OUTSIDE the container
  # directory. The cleaned path was then readable and would have been
  # streamed by `send_file` without further protest.
  #
  # The primitive was reachable via several entry points where the
  # local ad-hoc guards in `move_and_rename.rb` and `container_file.rb`
  # did NOT cover the value being sanitised:
  #   1. `file_name` flowing through `MoveAndRename#rename_file` ->
  #      `ContainerFile#move_to` -> `Filesystem.move_file_to_final_location`.
  #   2. Any persisted bad row in `nfs_store_stored_files` /
  #      `nfs_store_archived_files`; retrieval reassembles
  #      `container_root + path + file_name` with no containment check.
  #   3. Future / regressed entry points that omit the local guards,
  #      because there was no central descendant-of-root invariant in
  #      `Filesystem.nfs_store_path`.
  #
  # Now that `Filesystem.clean_path` rejects absolute paths, NUL bytes
  # and any input that resolves to a leading `..` segment — and
  # `Filesystem.nfs_store_path` re-validates user-supplied `path` and
  # `file_name` through `clean_path` before joining them onto the
  # container root — these POCs are inverted: the same attacker inputs
  # that previously read an arbitrary file now raise
  # `FsException::Action` at the boundary, and the planted secret file
  # is never reached.
  describe 'path traversal proof-of-concept (now blocked)' do
    let(:sandbox)   { Dir.mktmpdir('nfs_store_traversal_poc') }
    let(:secret_dir)    { File.join(sandbox, 'secrets') }
    let(:secret_name)   { 'PRIVATE.txt' }
    let(:secret_path)   { File.join(secret_dir, secret_name) }
    let(:secret_body)   { "TOP SECRET payload #{SecureRandom.hex(8)}" }

    before do
      FileUtils.mkdir_p secret_dir
      File.write(secret_path, secret_body)
    end

    after { FileUtils.remove_entry(sandbox) if File.exist?(sandbox) }

    it 'rejects a malicious `path` at the clean_path boundary' do
      # Attacker-controlled value, mirroring what ChunkController accepts
      # as `relative_path` before it is joined onto the container root.
      malicious_relative_path = '../../../../secrets'

      expect { described_class.clean_path(malicious_relative_path) }
        .to raise_error(FsException::Action)

      # Control: the planted secret really does exist on disk; the fix is
      # what prevents it from being reachable, not the absence of the file.
      expect(File.read(secret_path)).to eq(secret_body)
    end

    it 'rejects a malicious `file_name` at the clean_path boundary (rename vector)' do
      # Mirrors what `MoveAndRename#rename_file` -> `ContainerFile#move_to`
      # -> `Filesystem.move_file_to_final_location` -> `Filesystem.nfs_store_path`
      # now does: every user-supplied `file_name` is passed through
      # `clean_path` before being joined onto the container root.
      malicious_file_name = "../../../../../secrets/#{secret_name}"

      expect { described_class.clean_path(malicious_file_name) }
        .to raise_error(FsException::Action)

      expect(File.read(secret_path)).to eq(secret_body)
    end
  end

  # -------------------------------------------------------------------
  # Defense-in-depth: descendant-of-root invariant for nfs_store_path
  # -------------------------------------------------------------------
  #
  # `clean_path` defends user-supplied `path`/`file_name`, but other
  # fields contributing to the final assembly (container `parent_sub_dir`,
  # `directory_name`, archive mount names) come from model state and are
  # not currently passed through that sanitiser. If any of those values
  # were ever corrupted (compromised admin, broken migration, regressed
  # callback) they could cause the final path to escape the configured
  # containers root.
  #
  # The invariant: the final assembled path returned by
  # `nfs_store_path` must always be a descendant of
  # `<nfs_store_directory>/<mount>/<app-type-N>/<containers_dirname>`.
  describe '.nfs_store_path containment invariant' do
    let(:role_name) { 'r1' }
    let(:container) do
      double('Container',
             id: 123,
             app_type_id: 7,
             parent_sub_dir: malicious_parent,
             directory_name: 'safe-dir',
             current_user: nil)
    end

    before do
      allow(NfsStore::Manage::Group)
        .to receive(:nfs_mount_from_role_name).with(role_name).and_return('mount-x')
    end

    context 'when container.parent_sub_dir tries to escape via ".."' do
      let(:malicious_parent) { '../../../escape' }

      it 'raises FsException::Action rather than returning an escaped path' do
        expect { described_class.nfs_store_path(role_name, container, 'sub', 'file.txt') }
          .to raise_error(FsException::Action, /containment|descendant|escape/i)
      end
    end

    context 'when all inputs are benign' do
      let(:malicious_parent) { 'parent-a/parent-b' }

      it 'returns a path under the configured containers root' do
        result = described_class.nfs_store_path(role_name, container, 'sub', 'file.txt')
        root = File.join(described_class.nfs_store_directory, 'mount-x', 'app-type-7',
                         described_class.containers_dirname)
        expect(result).to start_with(root + '/')
      end
    end
  end

  # -------------------------------------------------------------------
  # .validate_file_name! — shared single-segment filename guard
  # -------------------------------------------------------------------
  #
  # `clean_path` is intentionally lenient about embedded forward slashes
  # because it deals with relative *paths* that may legitimately contain
  # subdirectories. A `file_name`, by contrast, must always be a single
  # path segment. This helper centralises that stricter contract so the
  # rename / upload / move entry points apply the same rules.
  describe '.validate_file_name!' do
    it 'returns the name unchanged when benign' do
      expect(described_class.validate_file_name!('report-2024.pdf')).to eq('report-2024.pdf')
    end

    it 'raises FsException::Action for nil' do
      expect { described_class.validate_file_name!(nil) }.to raise_error(FsException::Action)
    end

    it 'raises FsException::Action for blank' do
      expect { described_class.validate_file_name!('   ') }.to raise_error(FsException::Action)
    end

    it 'raises FsException::Action for "."' do
      expect { described_class.validate_file_name!('.') }.to raise_error(FsException::Action)
    end

    it 'raises FsException::Action for ".."' do
      expect { described_class.validate_file_name!('..') }.to raise_error(FsException::Action)
    end

    it 'raises FsException::Action for forward-slash separators' do
      expect { described_class.validate_file_name!('foo/bar.txt') }.to raise_error(FsException::Action)
    end

    it 'raises FsException::Action for backslash separators' do
      expect { described_class.validate_file_name!("foo\\bar.txt") }.to raise_error(FsException::Action)
    end

    it 'raises FsException::Action for embedded NUL' do
      expect { described_class.validate_file_name!("foo\x00bar.txt") }.to raise_error(FsException::Action)
    end

    it 'raises FsException::Action for embedded control characters' do
      expect { described_class.validate_file_name!("foo\nbar.txt") }.to raise_error(FsException::Action)
    end

    it 'raises FsException::Action for traversal payload' do
      expect { described_class.validate_file_name!('../../etc/passwd') }.to raise_error(FsException::Action)
    end
  end
end

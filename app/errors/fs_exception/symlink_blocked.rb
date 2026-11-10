module FsException
  # Raised when a container/archived file's resolved location is a symlink (or would
  # require following one), so it was refused rather than followed. A subclass of
  # FsException::Action so existing generic rescues still catch it; callers that want to
  # give a specific "blocked" response instead of a generic error can rescue this exactly.
  class SymlinkBlocked < Action
  end
end

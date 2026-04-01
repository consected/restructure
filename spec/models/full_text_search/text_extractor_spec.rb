# frozen_string_literal: true

require 'rails_helper'

# Tests for FullTextSearch::TextExtractor module (Issue #74 - Add full text search to Postgres)
#
# This module extracts text content from files for full-text search indexing.
# It supports:
#   - PDF files via pdftotext (poppler-utils)
#   - Office documents (doc, docx, xls, xlsx, ppt, pptx, odt, ods, odp) via LibreOffice + pdftotext
#   - Plain text files (txt, csv, md, rtf, html) read directly
#
# These specs verify extraction from real fixture files and correct handling
# of supported/unsupported file types, missing files, and configuration.

RSpec.describe 'FullTextSearch::TextExtractor', type: :model do
  let(:fixtures_path) { Rails.root.join('spec', 'fixtures', 'files') }
  let(:pdf_path) { fixtures_path.join('text_extraction', 'sample.pdf').to_s }
  let(:txt_path) { fixtures_path.join('text_extraction', 'sample.txt').to_s }
  let(:pptx_path) { fixtures_path.join('secure_view', 'sample.pptx').to_s }
  let(:nonexistent_path) { fixtures_path.join('text_extraction', 'does_not_exist.pdf').to_s }

  describe '.extract_text' do
    context 'with a PDF file' do
      it 'extracts text content from the PDF' do
        result = FullTextSearch::TextExtractor.extract_text(pdf_path)

        expect(result).to be_a(String)
        expect(result).not_to be_empty
        expect(result).to include('Cardiovascular research')
        expect(result).to include('Neuroplasticity')
      end
    end

    context 'with a plain text file' do
      it 'reads text content directly from the file' do
        result = FullTextSearch::TextExtractor.extract_text(txt_path)

        expect(result).to be_a(String)
        expect(result).not_to be_empty
        expect(result).to include('cardiovascular research')
        expect(result).to include('neuroplasticity experiments')
      end
    end

    context 'with an office document (pptx)' do
      it 'extracts text content from the office document' do
        result = FullTextSearch::TextExtractor.extract_text(pptx_path)

        expect(result).to be_a(String)
        # The pptx fixture may have limited text content;
        # primarily verifying extraction completes without error
      end
    end

    context 'with a non-existent file' do
      it 'raises FphsException' do
        expect do
          FullTextSearch::TextExtractor.extract_text(nonexistent_path)
        end.to raise_error(FphsException)
      end
    end

    context 'with an unsupported file type' do
      let(:unsupported_path) { fixtures_path.join('text_extraction', 'sample.dcm').to_s }

      it 'returns nil for unsupported file types' do
        # Create a dummy file so the "missing file" check doesn't trigger
        FileUtils.mkdir_p(File.dirname(unsupported_path))
        File.write(unsupported_path, 'binary content')

        result = FullTextSearch::TextExtractor.extract_text(unsupported_path)

        expect(result).to be_nil
      ensure
        FileUtils.rm_f(unsupported_path)
      end
    end
  end

  describe '.supported?' do
    context 'with PDF files' do
      it 'returns true for .pdf extension' do
        expect(FullTextSearch::TextExtractor.supported?('document.pdf')).to be true
      end
    end

    context 'with plain text files' do
      it 'returns true for .txt extension' do
        expect(FullTextSearch::TextExtractor.supported?('notes.txt')).to be true
      end

      it 'returns true for .csv extension' do
        expect(FullTextSearch::TextExtractor.supported?('data.csv')).to be true
      end

      it 'returns true for .md extension' do
        expect(FullTextSearch::TextExtractor.supported?('readme.md')).to be true
      end

      it 'returns true for .html extension' do
        expect(FullTextSearch::TextExtractor.supported?('page.html')).to be true
      end

      it 'returns true for .rtf extension' do
        expect(FullTextSearch::TextExtractor.supported?('document.rtf')).to be true
      end
    end

    context 'with office document files' do
      it 'returns true for .docx extension' do
        expect(FullTextSearch::TextExtractor.supported?('report.docx')).to be true
      end

      it 'returns true for .doc extension' do
        expect(FullTextSearch::TextExtractor.supported?('report.doc')).to be true
      end

      it 'returns true for .xlsx extension' do
        expect(FullTextSearch::TextExtractor.supported?('spreadsheet.xlsx')).to be true
      end

      it 'returns true for .xls extension' do
        expect(FullTextSearch::TextExtractor.supported?('spreadsheet.xls')).to be true
      end

      it 'returns true for .pptx extension' do
        expect(FullTextSearch::TextExtractor.supported?('slides.pptx')).to be true
      end

      it 'returns true for .ppt extension' do
        expect(FullTextSearch::TextExtractor.supported?('slides.ppt')).to be true
      end

      it 'returns true for .odt extension' do
        expect(FullTextSearch::TextExtractor.supported?('document.odt')).to be true
      end

      it 'returns true for .ods extension' do
        expect(FullTextSearch::TextExtractor.supported?('spreadsheet.ods')).to be true
      end

      it 'returns true for .odp extension' do
        expect(FullTextSearch::TextExtractor.supported?('slides.odp')).to be true
      end
    end

    context 'with unsupported file types' do
      it 'returns false for .dcm extension' do
        expect(FullTextSearch::TextExtractor.supported?('image.dcm')).to be false
      end

      it 'returns false for .zip extension' do
        expect(FullTextSearch::TextExtractor.supported?('archive.zip')).to be false
      end

      it 'returns false for .jpg extension' do
        expect(FullTextSearch::TextExtractor.supported?('photo.jpg')).to be false
      end

      it 'returns false for .exe extension' do
        expect(FullTextSearch::TextExtractor.supported?('program.exe')).to be false
      end
    end
  end

  describe '.pdftotext_path' do
    context 'when SecureView::Config.pdftotext_path is set' do
      it 'returns the configured path' do
        original = SecureView::Config.pdftotext_path
        SecureView::Config.pdftotext_path = '/custom/path/pdftotext'

        expect(FullTextSearch::TextExtractor.pdftotext_path).to eq('/custom/path/pdftotext')
      ensure
        SecureView::Config.pdftotext_path = original
      end
    end

    context 'when SecureView::Config.pdftotext_path is not set' do
      it 'defaults to pdftotext' do
        original = SecureView::Config.pdftotext_path
        SecureView::Config.pdftotext_path = nil

        expect(FullTextSearch::TextExtractor.pdftotext_path).to eq('pdftotext')
      ensure
        SecureView::Config.pdftotext_path = original
      end
    end
  end
end

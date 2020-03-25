# frozen_string_literal: true

module DicomSupport
  def test_dicom_files
    (0..9).map { |i| "00000#{i}.dcm" }
  end

  def upload_test_dicom_files
    @uploaded_files = []
    test_dicom_files.each do |f|
      dicom_content = File.read(File.join('spec', 'fixtures', 'files', 'dicom', f).to_s)
      @uploaded_files << upload_file(f, dicom_content)
    end
    @uploaded_files
  end
end

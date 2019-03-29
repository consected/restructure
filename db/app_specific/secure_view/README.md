# Secure View

Secure View for apps using Filestore provides users with an in-browser
facility for viewing files and documents, without the requirement to download them. The aim is to limit the risk of downloading files to insecure devices or storage, while still enabling users the ability to read them.

Based on user roles, specific functionality is presented:

* read files as images, without the ability to copy and paste text
* read files as HTML, allowing for basic access to data and copy and paste, without
* download file


## Installation

In addition to installation of a a recent version of the app, the following prerequisite programs must be installed on the app server.

### DCMTK - DICOM toolkit

To prepare installation assets for an external server, run the following and transfer the resulting file `dcmtk-3.6.4-install.tar.gz` to the target server. The Zeus build server is a good for this process.

    yum install -y cmake
    mkdir dcmtk
    cd dcmtk/
    curl -XGET ftp://dicom.offis.de/pub/dicom/offis/software/dcmtk/dcmtk364/dcmtk-3.6.4.tar.gz > dcmtk-3.6.4.tar.gz
    tar -xzf dcmtk-3.6.4.tar.gz
    mkdir dcmtk-gcc-`g++ -dumpversion`
    cd dcmtk-gcc-4.4.7/
    cmake ../dcmtk-3.6.4
    make -j8
    cd ../dcmtk-3.6.4-install
    cp -R usr/local/* /usr/
    dcmj2pnm --version
    make DESTDIR=../dcmtk-3.6.4-install install
    tar -zcvf dcmtk-3.6.4-install.tar.gz ../dcmtk-3.6.4-install

On the target server

    cd tmp
    mkdir dcmtk
    cd dcmtk/
    tar -xzf dcmtk-3.6.4-install.tar.gz
    rm dcmtk-3.6.4-install.tar.gz
    cd dcmtk-3.6.4-install
    cp -R usr/local/* /usr/
    dcmj2pnm --version


### LibreOffice and Poppler

    cd /tmp
    yum install -y cups

    wget https://mirror.clarkson.edu/tdf/libreoffice/stable/6.1.5/rpm/x86_64/LibreOffice_6.1.5_Linux_x86-64_rpm.tar.gz
    tar -xzf LibreOffice_6.1.5_Linux_x86-64_rpm.tar.gz
    rm LibreOffice_6.1.5_Linux_x86-64_rpm.tar.gz
    cd LibreOffice_6.1.5.2_Linux_x86-64_rpm/RPMS/
    yum localinstall -y *.rpm
    ln -s /usr/bin/libreoffice6.1 /usr/bin/soffice

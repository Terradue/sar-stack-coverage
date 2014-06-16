%define __jar_repack 0
Name: sar-stack-coverage
Version: 0.1
Release: ciop
Summary: sar-stack-coverage
License: ${project.inceptionYear}, Terradue, GPL
Distribution: Terradue ${project.inceptionYear}
Group: air
Packager: Terradue
Provides: sar-stack-coverage
autoprov: yes
autoreq: yes
Prefix: /application
BuildArch: noarch
BuildRoot: /home/fbrito/sar-stack-coverage/target/rpm/sar-stack-coverage/buildroot

%description
sar-stack-coverage

%install
if [ -d $RPM_BUILD_ROOT ];
then
  mv /home/fbrito/sar-stack-coverage/target/rpm/sar-stack-coverage/tmp-buildroot/* $RPM_BUILD_ROOT
else
  mv /home/fbrito/sar-stack-coverage/target/rpm/sar-stack-coverage/tmp-buildroot $RPM_BUILD_ROOT
fi

%files
%defattr(664,root,ciop,775)
 "/application"
%attr(775,root,ciop)  "/application/sar-stack/run.R"

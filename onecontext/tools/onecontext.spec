# Initial spec file created by autospec ver. 0.8 with rpm 3 compatibility
Summary: root
# The Summary: line should be expanded to about here -----^
Name: onecontext
Version: 1
Release: 0
Group: unknown
License: unknown
Source: onecontext-bin.tar.gz
BuildRoot: %{_tmppath}/%{name}-root
BuildArch: noarch

%description
root version unknown

%prep
%setup -c root

%install
%__cp -a . "${RPM_BUILD_ROOT-/}"

%clean
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf "$RPM_BUILD_ROOT"

%files
%defattr(-,root,root)
%dir /
%dir /usr/
%dir /usr/bin/
/usr/bin/onecontext
/usr/bin/quattorcontext
/etc/init.d/onecontext

%post
/sbin/chkconfig --add onecontext
/bin/mkdir -p /mnt/stratuslab

%preun
if [ $1 -eq 0 ]
then
  /sbin/chkconfig --del onecontext
fi

%changelog
* Thu Sep 25 2008 root <root@gridtest01.lal.in2p3.fr>
- Initial spec file created by autospec ver. 0.8 with rpm 3 compatibility

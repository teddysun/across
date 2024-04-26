#
# spec file for package xray-plugin
#
Name:           xray-plugin
Version:        1.8.11
Release:        1%{?dist}
Summary:        A SIP003 plugin for shadowsocks
License:        MIT
Group:          Productivity/Networking/Security
URL:            https://github.com/teddysun/xray-plugin
Source0:        %{name}-%{version}.tar.gz
BuildRequires:  bash

%global debug_package %{nil}
%global _missing_build_ids_terminate_build 0

%description
Yet another SIP003 plugin for shadowsocks, based on xray-core

%prep
%setup -q

%build

export CGO_ENABLED=0
go build -v -trimpath -ldflags "-X main.VERSION=v%{version} -s -w -buildid=" -o xray-plugin

%install
# install binary
install -D -p -m 0755 xray-plugin %{buildroot}%{_bindir}/xray-plugin

%files
%defattr(-,root,root)
%doc README.md
%{_bindir}/xray-plugin
%license LICENSE

%changelog
* Fri Apr 26 2024 Teddysun <i@teddysun.com> - 1.8.11-1
- Update to version 1.8.11

* Sat Mar 30 2024 Teddysun <i@teddysun.com> - 1.8.10-1
- Update to version 1.8.10

* Mon Mar 11 2024 Teddysun <i@teddysun.com> - 1.8.9-1
- Update to version 1.8.9

* Mon Feb 26 2024 Teddysun <i@teddysun.com> - 1.8.8-1
- Update to version 1.8.8

* Mon Jan 08 2024 Teddysun <i@teddysun.com> - 1.8.7-1
- Update to version 1.8.7

* Sat Nov 18 2023 Teddysun <i@teddysun.com> - 1.8.6-1
- Update to version 1.8.6

* Tue Nov 14 2023 Teddysun <i@teddysun.com> - 1.8.5-1
- Update to version 1.8.5

* Tue Aug 29 2023 Teddysun <i@teddysun.com> - 1.8.4-1
- Update version to 1.8.4

* Mon Jun 19 2023 Teddysun <i@teddysun.com> - 1.8.3-1
- Update version to 1.8.3

* Tue Apr 18 2023 Teddysun <i@teddysun.com> - 1.8.1-1
- Update version to 1.8.1

* Sat Mar 11 2023 Teddysun <i@teddysun.com> - 1.8.0-1
- Update version to 1.8.0

* Thu Feb 09 2023 Teddysun <i@teddysun.com> - 1.7.5-1
- Update version to 1.7.5

* Thu Feb 02 2023 Teddysun <i@teddysun.com> - 1.7.3-1
- Update version to 1.7.3

* Sun Jan 08 2023 Teddysun <i@teddysun.com> - 1.7.2-1
- Update version to 1.7.2

* Mon Dec 26 2022 Teddysun <i@teddysun.com> - 1.7.0-1
- Update version to 1.7.0

* Mon Dec 12 2022 Teddysun <i@teddysun.com> - 1.6.6-1
- Update version to 1.6.6

* Mon Nov 28 2022 Teddysun <i@teddysun.com> - 1.6.5-1
- Update version to 1.6.5

* Mon Nov 14 2022 Teddysun <i@teddysun.com> - 1.6.4-1
- Update version to 1.6.4

* Mon Nov 07 2022 Teddysun <i@teddysun.com> - 1.6.3-1
- Update version to 1.6.3

* Sat Oct 29 2022 Teddysun <i@teddysun.com> - 1.6.2-1
- Update version to 1.6.2

* Sat Oct 22 2022 Teddysun <i@teddysun.com> - 1.6.1-1
- Update version to 1.6.1

* Tue Sep 20 2022 Teddysun <i@teddysun.com> - 1.6.0-1
- Update version to 1.6.0

* Mon Aug 29 2022 Teddysun <i@teddysun.com> - 1.5.10-1
- Update version to 1.5.10

* Sat Jul 16 2022 Teddysun <i@teddysun.com> - 1.5.9-1
- Update version to 1.5.9

* Mon Jun 20 2022 Teddysun <i@teddysun.com> - 1.5.8-1
- Update version to 1.5.8

* Thu Jun 16 2022 Teddysun <i@teddysun.com> - 1.5.7-1
- Update version to 1.5.7

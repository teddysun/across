%global debug_package %{nil}

Name:           xray
Version:        24.11.30
Release:        1%{?dist}
Summary:        Xray, Penetrates Everything.
License:        MPL-2.0
URL:            https://github.com/XTLS/Xray-core
Packager:       Teddysun <i@teddysun.com>

Source0:        https://github.com/XTLS/Xray-core/archive/refs/tags/v%{version}.tar.gz#/Xray-core-%{version}.tar.gz
Source1:        https://github.com/teddysun/across/raw/master/rpm/xray/config.json
Source2:        https://github.com/v2fly/geoip/releases/latest/download/geoip.dat
Source3:        https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat

#BuildRequires:  golang >= 1.20
%if 0%{?rhel} && 0%{?rhel} < 8
BuildRequires:  systemd
%else
BuildRequires:  systemd-rpm-macros
%endif
%{?systemd_requires}
Provides:       Productivity/Networking/Web/Proxy

%description
Xray, Penetrates Everything.
Also the best v2ray-core, with XTLS support. Fully compatible configuration.

%prep
%setup -q -n Xray-core-%{version}

%build
# https://pagure.io/go-rpm-macros/c/1cc7f5d9026175bb6cb1b8c889355d0c4fc0e40a
%undefine _auto_set_build_flags

LDFLAGS='-s -w -buildid='
env CGO_ENABLED=0 go build -v -trimpath -ldflags "$LDFLAGS" -o %{name} ./main

%install
%{__install} -d %{buildroot}%{_bindir}
%{__install} -p -m 755 %{name} %{buildroot}%{_bindir}

%{__install} -d %{buildroot}%{_sysconfdir}/%{name}
%{__install} -p -m 644 %{S:1} %{buildroot}%{_sysconfdir}/%{name}/config.json

%{__install} -d %{buildroot}%{_datadir}/%{name}
%{__install} -p -m 0644 %{S:2} %{buildroot}%{_datadir}/%{name}/geoip.dat
%{__install} -p -m 0644 %{S:3} %{buildroot}%{_datadir}/%{name}/geosite.dat

%{__install} -d %{buildroot}%{_unitdir}
cat > %{buildroot}%{_unitdir}/%{name}.service <<EOF
[Unit]
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/bin/xray run -config /etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF
cat > %{buildroot}%{_unitdir}/%{name}@.service <<EOF
[Unit]
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/bin/xray run -config /etc/xray/%i.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF


%post
%systemd_post %{name}.service

%preun
%systemd_preun %{name}.service

%postun
%systemd_postun_with_restart %{name}.service

%files
%{_bindir}/%{name}
%{_unitdir}/%{name}.service
%{_unitdir}/%{name}@.service
%dir %{_sysconfdir}/%{name}
%config(noreplace) %{_sysconfdir}/%{name}/config.json
%{_datadir}/%{name}/*.dat
%license LICENSE
%doc README.md

%changelog
* Sat Nov 30 2024 Teddysun <i@teddysun.com> - 24.11.30-1
- Update version to 24.11.30

* Thu Nov 21 2024 Teddysun <i@teddysun.com> - 24.11.21-1
- Update version to 24.11.21

* Mon Nov 11 2024 Teddysun <i@teddysun.com> - 24.11.11-1
- Update version to 24.11.11

* Tue Nov 05 2024 Teddysun <i@teddysun.com> - 24.11.5-1
- Update version to 24.11.5

* Thu Oct 31 2024 Teddysun <i@teddysun.com> - 24.10.31-1
- Update version to 24.10.31

* Wed Oct 16 2024 Teddysun <i@teddysun.com> - 24.10.16-1
- Update version to 24.10.16

* Mon Sep 30 2024 Teddysun <i@teddysun.com> - 24.9.30-1
- Update version to 24.9.30

* Thu Sep 19 2024 Teddysun <i@teddysun.com> - 24.9.19-1
- Update version to 24.9.19

* Mon Sep 16 2024 Teddysun <i@teddysun.com> - 24.9.16-1
- Update version to 24.9.16

* Sat Sep 07 2024 Teddysun <i@teddysun.com> - 24.9.7-1
- Update version to 24.9.7 (New version naming rule, based release date)

* Fri Aug 30 2024 Teddysun <i@teddysun.com> - 1.8.24-1
- Update version to 1.8.24

* Sun Aug 04 2024 Teddysun <i@teddysun.com> - 1.8.23-1
- Update to version 1.8.23

* Wed Jul 17 2024 Teddysun <i@teddysun.com> - 1.8.19-1
- Update to version 1.8.19

* Mon Jul 15 2024 Teddysun <i@teddysun.com> - 1.8.18-1
- Update to version 1.8.18

* Fri Jul 12 2024 Teddysun <i@teddysun.com> - 1.8.17-1
- Update to version 1.8.17

* Fri Jun 21 2024 Teddysun <i@teddysun.com> - 1.8.16-1
- Update to version 1.8.16

* Tue Jun 18 2024 Teddysun <i@teddysun.com> - 1.8.15-1
- Update to version 1.8.15

* Thu May 23 2024 Teddysun <i@teddysun.com> - 1.8.13-1
- Update to version 1.8.13

* Wed May 22 2024 Teddysun <i@teddysun.com> - 1.8.12-1
- Update to version 1.8.12

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

* Wed Oct 18 2023 Teddysun <i@teddysun.com> - 1.8.4-1
- Update to version 1.8.4

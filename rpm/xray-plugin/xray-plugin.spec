#
# spec file for package xray-plugin
#
Name:           xray-plugin
Version:        1.8.15
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

# Proposal: macOS arm64 Chromium Build

Create a reliable first-pass build pipeline for Bugmax on macOS arm64 using a
self-hosted Apple Silicon runner.

The first pass must build vanilla Chromium and package it as Bugmax without
unverified source patches. Signing and notarization are optional workflow inputs
that depend on Apple Developer ID configuration.

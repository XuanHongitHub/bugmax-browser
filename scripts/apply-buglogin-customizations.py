#!/usr/bin/env python3
import pathlib
import struct
import sys
import zlib


APP_NAME = "Bugmax"
BUNDLE_ID = "com.buglogin.bugmax"


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


def write_text(path: pathlib.Path, data: str) -> None:
    path.write_text(data, encoding="utf-8", newline="\n")


def replace_once(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise RuntimeError(f"missing anchor: {label}")
    return text.replace(old, new, 1)


def patch_branding(src: pathlib.Path) -> None:
    path = src / "chrome/app/theme/chromium/BRANDING"
    text = read_text(path)
    replacements = {
        "COMPANY_FULLNAME=The Chromium Authors": "COMPANY_FULLNAME=BugLogin",
        "COMPANY_SHORTNAME=The Chromium Authors": "COMPANY_SHORTNAME=BugLogin",
        "PRODUCT_FULLNAME=Chromium": f"PRODUCT_FULLNAME={APP_NAME}",
        "PRODUCT_SHORTNAME=Chromium": f"PRODUCT_SHORTNAME={APP_NAME}",
        "PRODUCT_INSTALLER_FULLNAME=Chromium Installer": f"PRODUCT_INSTALLER_FULLNAME={APP_NAME} Installer",
        "PRODUCT_INSTALLER_SHORTNAME=Chromium Installer": f"PRODUCT_INSTALLER_SHORTNAME={APP_NAME} Installer",
        "COPYRIGHT=Copyright @LASTCHANGE_YEAR@ The Chromium Authors. All rights reserved.": "COPYRIGHT=Copyright @LASTCHANGE_YEAR@ BugLogin. All rights reserved.",
        "MAC_BUNDLE_ID=org.chromium.Chromium": f"MAC_BUNDLE_ID={BUNDLE_ID}",
    }
    for old, new in replacements.items():
        if old not in text and new not in text:
            raise RuntimeError(f"missing branding field: {old}")
        text = text.replace(old, new)
    write_text(path, text)


def png_rgba(width: int, height: int, rgba: bytes) -> bytes:
    def chunk(kind: bytes, data: bytes) -> bytes:
        return (
            struct.pack(">I", len(data))
            + kind
            + data
            + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)
        )

    raw = b"".join(b"\x00" + rgba[y * width * 4 : (y + 1) * width * 4] for y in range(height))
    return (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(raw, 9))
        + chunk(b"IEND", b"")
    )


def bugmax_icon(size: int) -> bytes:
    bg = (14, 24, 38, 255)
    primary = (35, 180, 140, 255)
    light = (235, 250, 245, 255)
    data = bytearray()
    for y in range(size):
        for x in range(size):
            # Rounded-ish square background.
            m = int(size * 0.08)
            r = int(size * 0.18)
            inside = m <= x < size - m and m <= y < size - m
            corner = False
            for cx, cy in ((m + r, m + r), (size - m - r, m + r), (m + r, size - m - r), (size - m - r, size - m - r)):
                if abs(x - cx) > r and abs(y - cy) > r:
                    continue
                corner = True
            color = bg if inside or corner else (0, 0, 0, 0)
            # Geometric B mark.
            bx0, bx1 = int(size * 0.28), int(size * 0.40)
            by0, by1 = int(size * 0.24), int(size * 0.76)
            if bx0 <= x <= bx1 and by0 <= y <= by1:
                color = light
            for cy in (int(size * 0.38), int(size * 0.62)):
                cx = int(size * 0.52)
                rr = int(size * 0.17)
                dist = (x - cx) * (x - cx) + (y - cy) * (y - cy)
                if dist <= rr * rr and x >= bx1:
                    color = primary
                if dist <= int(rr * 0.55) * int(rr * 0.55) and x >= bx1:
                    color = bg
            data.extend(color)
    return png_rgba(size, size, bytes(data))


def patch_icons(src: pathlib.Path) -> None:
    theme = src / "chrome/app/theme/chromium"
    for size in (16, 32, 48, 64, 128, 256):
        path = theme / f"product_logo_{size}.png"
        if path.exists():
            path.write_bytes(bugmax_icon(size))


def patch_location_bar_h(src: pathlib.Path) -> None:
    path = src / "chrome/browser/ui/views/location_bar/location_bar_view.h"
    text = read_text(path)
    if "UpdateBugLoginProfileBadge" not in text:
        anchor = (
            "  // Helper to set the texts of labels adjacent to the omnibox:\n"
            "  // `ime_inline_autocomplete_view_`, and `omnibox_additional_text_view_`.\n"
            "  void SetOmniboxAdjacentText(views::Label* label, std::u16string_view text);\n\n"
        )
        text = replace_once(
            text,
            anchor,
            anchor
            + "  // Updates BugLogin profile badge text in front of the omnibox.\n"
            + "  void UpdateBugLoginProfileBadge();\n\n",
            "location_bar_view.h method",
        )
    if "buglogin_profile_badge_label_" not in text:
        anchor = (
            "  raw_ptr<views::Label> omnibox_additional_text_view_ = nullptr;\n\n"
        )
        text = replace_once(
            text,
            anchor,
            anchor
            + "  // BugLogin profile badge shown before omnibox text.\n"
            + "  raw_ptr<views::Label> buglogin_profile_badge_label_ = nullptr;\n\n",
            "location_bar_view.h member",
        )
    write_text(path, text)


def patch_location_bar_cc(src: pathlib.Path) -> None:
    path = src / "chrome/browser/ui/views/location_bar/location_bar_view.cc"
    text = read_text(path)
    if '#include "base/environment.h"' not in text:
        text = replace_once(
            text,
            '#include "base/containers/adapters.h"\n',
            '#include "base/environment.h"\n#include "base/containers/adapters.h"\n',
            "location_bar_view.cc include",
        )
    if "kBugLoginProfileNameEnv" not in text:
        text = replace_once(
            text,
            "constexpr int kContentSettingIntraItemPadding = 8;\n\n",
            "constexpr int kContentSettingIntraItemPadding = 8;\n\n"
            'constexpr char kBugLoginProfileNameEnv[] = "BUGLOGIN_PROFILE_NAME";\n'
            'constexpr char kBugmaxProfileNameEnv[] = "BUGMAX_PROFILE_NAME";\n\n',
            "location_bar_view.cc constants",
        )
    if "buglogin_profile_badge_label_ = AddChildView" not in text:
        anchor = (
            "  omnibox_additional_text_view_ =\n"
            "      AddChildView(std::move(omnibox_additional_text_view));\n"
            "  omnibox_additional_text_view_->SetEnabledColor(kColorOmniboxResultsUrl);\n\n"
        )
        text = replace_once(
            text,
            anchor,
            anchor
            + "  auto buglogin_profile_badge_label = std::make_unique<views::Label>(\n"
            + "      std::u16string(), CONTEXT_OMNIBOX_PRIMARY,\n"
            + "      views::style::STYLE_BODY_4_EMPHASIS);\n"
            + "  buglogin_profile_badge_label->SetHorizontalAlignment(gfx::ALIGN_LEFT);\n"
            + "  buglogin_profile_badge_label->SetElideBehavior(gfx::ELIDE_TAIL);\n"
            + "  buglogin_profile_badge_label->SetVisible(false);\n"
            + "  buglogin_profile_badge_label_ =\n"
            + "      AddChildView(std::move(buglogin_profile_badge_label));\n"
            + "  buglogin_profile_badge_label_->SetEnabledColor(kColorOmniboxResultsUrl);\n"
            + "  UpdateBugLoginProfileBadge();\n\n",
            "location_bar_view.cc badge create",
        )
    if "void LocationBarView::UpdateBugLoginProfileBadge()" not in text:
        anchor = (
            "std::u16string_view LocationBarView::GetOmniboxAdditionalText() const {\n"
            "  return omnibox_additional_text_view_->GetText();\n"
            "}\n\n"
        )
        text = replace_once(
            text,
            anchor,
            anchor
            + "void LocationBarView::UpdateBugLoginProfileBadge() {\n"
            + "  if (!buglogin_profile_badge_label_) {\n"
            + "    return;\n"
            + "  }\n"
            + "  auto environment = base::Environment::Create();\n"
            + "  std::string profile_name_utf8;\n"
            + "  if ((!environment || !environment->GetVar(kBugLoginProfileNameEnv,\n"
            + "                                             &profile_name_utf8)) ||\n"
            + "      profile_name_utf8.empty()) {\n"
            + "    if (environment) {\n"
            + "      environment->GetVar(kBugmaxProfileNameEnv, &profile_name_utf8);\n"
            + "    }\n"
            + "  }\n"
            + "  if (profile_name_utf8.empty()) {\n"
            + "    SetOmniboxAdjacentText(buglogin_profile_badge_label_, std::u16string());\n"
            + "    buglogin_profile_badge_label_->SetTooltipText(std::u16string());\n"
            + "    return;\n"
            + "  }\n"
            + "  std::u16string profile_name = base::UTF8ToUTF16(profile_name_utf8);\n"
            + "  SetOmniboxAdjacentText(buglogin_profile_badge_label_, profile_name);\n"
            + "  buglogin_profile_badge_label_->SetTooltipText(profile_name);\n"
            + "}\n\n",
            "location_bar_view.cc badge method",
        )
    if "buglogin_profile_badge_label_->GetVisible()" not in text:
        anchor = (
            "  } else {\n"
            "    location_icon_view_->SetVisible(false);\n"
            "  }\n\n"
        )
        text = replace_once(
            text,
            anchor,
            anchor
            + "  if (buglogin_profile_badge_label_ &&\n"
            + "      buglogin_profile_badge_label_->GetVisible()) {\n"
            + "    leading_decorations.AddDecoration(\n"
            + "        vertical_padding, location_height, false, 0,\n"
            + "        GetLayoutConstant(LayoutConstant::kLocationBarElementPadding),\n"
            + "        icon_left, buglogin_profile_badge_label_);\n"
            + "  }\n\n",
            "location_bar_view.cc badge layout",
        )
    if "UpdateBugLoginProfileBadge();\n  InvalidateLayout();" not in text:
        text = replace_once(
            text,
            "  InvalidateLayout();\n",
            "  UpdateBugLoginProfileBadge();\n  InvalidateLayout();\n",
            "location_bar_view.cc onchanged",
        )
    if "buglogin_profile_badge_label_->SetFontList(font_list);" not in text:
        text = replace_once(
            text,
            "  omnibox_additional_text_view_->SetFontList(font_list);\n",
            "  omnibox_additional_text_view_->SetFontList(font_list);\n"
            "  if (buglogin_profile_badge_label_) {\n"
            "    buglogin_profile_badge_label_->SetFontList(font_list);\n"
            "  }\n",
            "location_bar_view.cc touch",
        )
    write_text(path, text)


def patch_autocomplete_input(src: pathlib.Path) -> None:
    path = src / "components/omnibox/browser/autocomplete_input.cc"
    text = read_text(path)
    if "BugLogin: plain multi-token input" not in text:
        anchor = (
            "  if (first_non_white == std::u16string::npos)\n"
            "    return metrics::OmniboxInputType::EMPTY;  // All whitespace.\n\n"
        )
        text = replace_once(
            text,
            anchor,
            anchor
            + "  // BugLogin: plain multi-token input should search, not navigate.\n"
            + "  const bool buglogin_has_space =\n"
            + "      text.find_first_of(base::kWhitespaceUTF16) != std::u16string::npos;\n"
            + "  const bool buglogin_has_scheme = text.find(u\"://\") != std::u16string::npos;\n"
            + "  const bool buglogin_has_url_marker =\n"
            + "      text.find(u\"/\") != std::u16string::npos ||\n"
            + "      text.find(u\".\") != std::u16string::npos;\n"
            + "  if (buglogin_has_space && !buglogin_has_scheme &&\n"
            + "      !buglogin_has_url_marker) {\n"
            + "    return metrics::OmniboxInputType::QUERY;\n"
            + "  }\n\n",
            "autocomplete_input.cc search bias",
        )
    write_text(path, text)


def patch_omnibox_prefs(src: pathlib.Path) -> None:
    path = src / "components/omnibox/browser/omnibox_prefs.cc"
    text = read_text(path)
    if "kBugLoginFirstRunDefaultsApplied" not in text:
        text = replace_once(
            text,
            "namespace omnibox {\n\n",
            "namespace omnibox {\n\n"
            'constexpr char kBugLoginFirstRunDefaultsApplied[] = "buglogin.first_run_defaults";\n\n',
            "omnibox_prefs.cc const",
        )
        text = replace_once(
            text,
            "  registry->RegisterIntegerPref(kAimHintTotalImpressions, 0);\n",
            "  registry->RegisterIntegerPref(kAimHintTotalImpressions, 0);\n"
            "  registry->RegisterBooleanPref(kBugLoginFirstRunDefaultsApplied, true);\n",
            "omnibox_prefs.cc register",
        )
    write_text(path, text)


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: apply-buglogin-customizations.py <chromium-src-root>", file=sys.stderr)
        return 2
    src = pathlib.Path(sys.argv[1]).resolve()
    patch_branding(src)
    patch_icons(src)
    patch_location_bar_h(src)
    patch_location_bar_cc(src)
    patch_autocomplete_input(src)
    patch_omnibox_prefs(src)
    print("BugLogin Chromium customizations applied.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

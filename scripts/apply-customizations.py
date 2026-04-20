#!/usr/bin/env python3
import pathlib
import re
import sys


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8")


def write_text(path: pathlib.Path, data: str) -> None:
    path.write_text(data, encoding="utf-8", newline="\n")


def replace_or_fail(text: str, old: str, new: str, label: str) -> str:
    if old not in text:
        raise RuntimeError(f"Missing anchor for {label}")
    return text.replace(old, new, 1)


def ensure_contains(text: str, snippet: str) -> bool:
    return snippet in text


def patch_branding(src: pathlib.Path) -> None:
    path = src / "chrome/app/theme/chromium/BRANDING"
    text = read_text(path)
    replacements = {
        "COMPANY_FULLNAME=The Chromium Authors": "COMPANY_FULLNAME=BugLogin",
        "COMPANY_SHORTNAME=The Chromium Authors": "COMPANY_SHORTNAME=BugLogin",
        "PRODUCT_FULLNAME=Chromium": "PRODUCT_FULLNAME=Bugmax",
        "PRODUCT_SHORTNAME=Chromium": "PRODUCT_SHORTNAME=Bugmax",
        "PRODUCT_INSTALLER_FULLNAME=Chromium Installer": "PRODUCT_INSTALLER_FULLNAME=Bugmax Installer",
        "PRODUCT_INSTALLER_SHORTNAME=Chromium Installer": "PRODUCT_INSTALLER_SHORTNAME=Bugmax Installer",
        "COPYRIGHT=Copyright @LASTCHANGE_YEAR@ The Chromium Authors. All rights reserved.": "COPYRIGHT=Copyright @LASTCHANGE_YEAR@ BugLogin. All rights reserved.",
        "MAC_BUNDLE_ID=org.chromium.Chromium": "MAC_BUNDLE_ID=com.buglogin.bugmax",
    }
    for old, new in replacements.items():
        text = text.replace(old, new)
    write_text(path, text)


def patch_location_bar_h(src: pathlib.Path) -> None:
    path = src / "chrome/browser/ui/views/location_bar/location_bar_view.h"
    text = read_text(path)
    decl = (
        "  // Refreshes the profile badge shown in front of the omnibox input.\n"
        "  // Value is read from environment variable BUGMAX_PROFILE_NAME.\n"
        "  void UpdateProfileBadge();\n\n"
    )
    if "void UpdateProfileBadge();" not in text:
        anchor = (
            "  // Helper to set the texts of labels adjacent to the omnibox:\n"
            "  // `ime_inline_autocomplete_view_`, and `omnibox_additional_text_view_`.\n"
            "  void SetOmniboxAdjacentText(views::Label* label, std::u16string_view text);\n\n"
        )
        text = replace_or_fail(text, anchor, anchor + decl, "location_bar_view.h decl")

    member = "  raw_ptr<views::Label> profile_badge_label_ = nullptr;\n\n"
    if "profile_badge_label_" not in text:
        anchor = (
            "  // The complementary omnibox label displaying the selected suggestion's title\n"
            "  // or URL when the omnibox view is displaying the other and when user input is\n"
            "  // in progress. Will remain a nullptr if the rich autocompletion\n"
            "  // feature flag is disabled.\n"
            "  raw_ptr<views::Label> omnibox_additional_text_view_ = nullptr;\n\n"
        )
        insertion = (
            "  // Optional profile badge displayed before omnibox text.\n"
            + member
        )
        text = replace_or_fail(text, anchor, anchor + insertion, "location_bar_view.h member")
    write_text(path, text)


def patch_location_bar_cc(src: pathlib.Path) -> None:
    path = src / "chrome/browser/ui/views/location_bar/location_bar_view.cc"
    text = read_text(path)
    if '#include "base/environment.h"' not in text:
        text = replace_or_fail(
            text,
            '#include "base/containers/adapters.h"\n',
            '#include "base/environment.h"\n#include "base/containers/adapters.h"\n',
            "location_bar_view.cc include",
        )
    if 'constexpr char kBugmaxProfileNameEnv[] = "BUGMAX_PROFILE_NAME";' not in text:
        text = replace_or_fail(
            text,
            "constexpr int kContentSettingIntraItemPadding = 8;\n\n",
            "constexpr int kContentSettingIntraItemPadding = 8;\n\n"
            "// Environment key controlling the omnibox profile badge text.\n"
            'constexpr char kBugmaxProfileNameEnv[] = "BUGMAX_PROFILE_NAME";\n\n',
            "location_bar_view.cc constant",
        )

    if "profile_badge_label_ = AddChildView" not in text:
        anchor = (
            "  auto location_icon_view =\n"
            "      std::make_unique<LocationIconView>(omnibox_chip_font_list, this, this);\n"
            "  location_icon_view->set_drag_controller(this);\n"
            "  location_icon_view_ = AddChildView(std::move(location_icon_view));\n\n"
        )
        block = (
            "  auto profile_badge_label = std::make_unique<views::Label>(\n"
            "      std::u16string(), views::Label::CustomFont{font_list});\n"
            "  profile_badge_label->SetHorizontalAlignment(gfx::ALIGN_CENTER);\n"
            "  profile_badge_label->SetElideBehavior(gfx::ELIDE_TAIL);\n"
            "  profile_badge_label->SetVisible(false);\n"
            "  profile_badge_label->SetAutoColorReadabilityEnabled(false);\n"
            "  profile_badge_label->SetBackground(views::CreateRoundedRectBackground(\n"
            "      GetColorProvider()->GetColor(kColorOmniboxResultsTextDimmed), 6));\n"
            "  profile_badge_label_ = AddChildView(std::move(profile_badge_label));\n"
            "  UpdateProfileBadge();\n\n"
        )
        text = replace_or_fail(text, anchor, anchor + block, "location_bar_view.cc badge view")

    if "void LocationBarView::UpdateProfileBadge()" not in text:
        anchor = (
            "std::u16string_view LocationBarView::GetOmniboxAdditionalText() const {\n"
            "  return omnibox_additional_text_view_->GetText();\n"
            "}\n\n"
        )
        block = (
            "void LocationBarView::UpdateProfileBadge() {\n"
            "  if (!profile_badge_label_) {\n"
            "    return;\n"
            "  }\n\n"
            "  auto environment = base::Environment::Create();\n"
            "  std::string profile_name_utf8;\n"
            "  if (!environment || !environment->GetVar(kBugmaxProfileNameEnv,\n"
            "                                           &profile_name_utf8) ||\n"
            "      profile_name_utf8.empty()) {\n"
            "    SetOmniboxAdjacentText(profile_badge_label_, std::u16string());\n"
            "    profile_badge_label_->SetTooltipText(std::u16string());\n"
            "    return;\n"
            "  }\n\n"
            "  std::u16string profile_name = base::UTF8ToUTF16(profile_name_utf8);\n"
            "  std::u16string badge_text = u\"[\";\n"
            "  badge_text += profile_name;\n"
            "  badge_text += u\"]\";\n"
            "  SetOmniboxAdjacentText(profile_badge_label_, badge_text);\n"
            "  profile_badge_label_->SetTooltipText(profile_name);\n"
            "}\n\n"
        )
        text = replace_or_fail(text, anchor, anchor + block, "location_bar_view.cc badge method")

    if "profile_badge_label_ && profile_badge_label_->GetVisible()" not in text:
        anchor = (
            "  } else {\n"
            "    location_icon_view_->SetVisible(false);\n"
            "  }\n\n"
        )
        block = (
            "  if (profile_badge_label_ && profile_badge_label_->GetVisible()) {\n"
            "    const int badge_padding =\n"
            "        GetLayoutConstant(LayoutConstant::kLocationBarElementPadding);\n"
            "    leading_decorations.AddDecoration(vertical_padding, location_height, false,\n"
            "                                      0, badge_padding, text_left,\n"
            "                                      profile_badge_label_);\n"
            "  }\n\n"
        )
        text = replace_or_fail(text, anchor, anchor + block, "location_bar_view.cc layout")

    if "\n  UpdateProfileBadge();\n  InvalidateLayout();" not in text:
        text = replace_or_fail(
            text,
            "\n  InvalidateLayout();\n",
            "\n  UpdateProfileBadge();\n  InvalidateLayout();\n",
            "location_bar_view.cc onchange",
        )

    if "profile_badge_label_->SetFontList(font_list);" not in text:
        text = replace_or_fail(
            text,
            "  omnibox_additional_text_view_->SetFontList(font_list);\n",
            "  omnibox_additional_text_view_->SetFontList(font_list);\n"
            "  if (profile_badge_label_) {\n"
            "    profile_badge_label_->SetFontList(font_list);\n"
            "  }\n",
            "location_bar_view.cc ontouch",
        )

    write_text(path, text)


def patch_autocomplete_input(src: pathlib.Path) -> None:
    path = src / "components/omnibox/browser/autocomplete_input.cc"
    text = read_text(path)
    marker = "const bool has_space ="
    if marker not in text:
        anchor = (
            "  if (first_non_white == std::u16string::npos)\n"
            "    return metrics::OmniboxInputType::EMPTY;  // All whitespace.\n\n"
        )
        block = (
            "  // Bugmax rule: for plain whitespace queries that do not look like explicit\n"
            "  // URLs, bias toward search classification to avoid accidental navigation to\n"
            "  // malformed hostnames (for example: \"seller temu\" -> \"http://seller%20temu\").\n"
            "  const bool has_space =\n"
            "      text.find_first_of(base::kWhitespaceUTF16) != std::u16string::npos;\n"
            "  const bool has_explicit_scheme = text.find(u\"://\") != std::u16string::npos;\n"
            "  const bool has_path_or_known_url_delimiter =\n"
            "      text.find(u\"/\") != std::u16string::npos ||\n"
            "      text.find(u\".\") != std::u16string::npos;\n"
            "  if (has_space && !has_explicit_scheme && !has_path_or_known_url_delimiter)\n"
            "    return metrics::OmniboxInputType::QUERY;\n\n"
        )
        text = replace_or_fail(text, anchor, anchor + block, "autocomplete_input.cc")
    write_text(path, text)


def patch_omnibox_prefs(src: pathlib.Path) -> None:
    path = src / "components/omnibox/browser/omnibox_prefs.cc"
    text = read_text(path)
    if "kBugmaxFirstRunDefaultsApplied" not in text:
        text = replace_or_fail(
            text,
            "namespace omnibox {\n\n",
            "namespace omnibox {\n\n"
            "// Bugmax-specific marker pref to help identify first-run default seeding.\n"
            'constexpr char kBugmaxFirstRunDefaultsApplied[] = "bugmax.first_run_defaults";\n\n',
            "omnibox_prefs.cc const",
        )
        text = replace_or_fail(
            text,
            "  registry->RegisterIntegerPref(kAimHintTotalImpressions, 0);\n",
            "  registry->RegisterIntegerPref(kAimHintTotalImpressions, 0);\n"
            "  registry->RegisterBooleanPref(kBugmaxFirstRunDefaultsApplied, true);\n",
            "omnibox_prefs.cc register",
        )
    write_text(path, text)


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: apply-customizations.py <chromium-src-root>", file=sys.stderr)
        return 2
    src = pathlib.Path(sys.argv[1]).resolve()
    patch_branding(src)
    patch_location_bar_h(src)
    patch_location_bar_cc(src)
    patch_autocomplete_input(src)
    patch_omnibox_prefs(src)
    print("Bugmax customizations applied.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

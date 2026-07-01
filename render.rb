#!/usr/bin/env ruby
# Renders localized copies of the real index/support/privacy pages into per-URL-slug
# directories, preserving the exact design and fixing asset depth / canonical URLs /
# lang+dir. Source of truth for text = i18n/*.json. Fails loudly if any English anchor
# is not found (so no string can silently remain English) or any key is missing.
require "json"

ROOT = File.expand_path(File.dirname(__FILE__))
BASE = "https://juanca-jimi.github.io/metronome"

# slug => BCP47 lang tag, for the 7 fully-translated languages.
TRANSLATED = {
  "ar" => "ar", "de" => "de", "es" => "es", "fr" => "fr",
  "ja" => "ja", "ko" => "ko", "zh-hans" => "zh-Hans",
}
# URL slugs that fall back to English content (URL resolves, content is the English page).
FALLBACK = %w[
  bn ca cs da el fi gu he hi hr hu id it kn ml mr ms nl no or pa pl
  pt-BR pt ro ru sk sl sv ta te th tr uk ur vi zh-hant
]
RTL = %w[ar]

EN = JSON.parse(File.read("#{ROOT}/i18n/en.json"))

def load_tr(file, en)
  tr = JSON.parse(File.read(file))
  missing = en.keys - tr.keys
  raise "#{file}: missing keys #{missing.join(', ')}" unless missing.empty?
  en.merge(tr) # ensure every key present; translated values win
end

# --- Build a template from a real page by replacing English HTML with {{key}} anchors.
# Each entry is [exact_old_html, replacement]. We assert old_html is present.
def templatize(html, repls, page)
  html = html.dup
  repls.each do |old, neu|
    unless html.include?(old)
      raise "[#{page}] anchor not found:\n#{old.inspect}"
    end
    html = html.sub(old, neu) # first occurrence; anchors are unique per intent
  end
  html
end

# Marketing (index) page ----------------------------------------------------------
INDEX_REPLS = [
  ['<html lang="en">', '<html lang="{{LANG}}"{{DIRATTR}}>'],
  ['<title>Metronome — A premium metronome for working musicians</title>', '<title>{{idx_title}}</title>'],
  ['content="Sample-accurate timing, polyrhythms, mixed meter, MIDI clock, and Ableton Link — wrapped in 11 hand-crafted themes. Coming to iOS."', 'content="{{idx_meta_desc}}"'],
  ['<link rel="canonical" href="https://juanca-jimi.github.io/metronome/" />', '<link rel="canonical" href="{{CANON}}" />'],
  ['<meta property="og:title" content="Metronome — A premium metronome for working musicians" />', '<meta property="og:title" content="{{idx_title}}" />'],
  ['<meta property="og:description" content="Sample-accurate timing, polyrhythms, mixed meter, MIDI clock, and Ableton Link." />', '<meta property="og:description" content="{{idx_og_desc}}" />'],
  ['<meta property="og:url" content="https://juanca-jimi.github.io/metronome/" />', '<meta property="og:url" content="{{CANON}}" />'],
  ['<meta name="twitter:title" content="Metronome — A premium metronome for working musicians" />', '<meta name="twitter:title" content="{{idx_title}}" />'],
  ['<meta name="twitter:description" content="Sample-accurate timing, polyrhythms, mixed meter, MIDI clock, and Ableton Link." />', '<meta name="twitter:description" content="{{idx_og_desc}}" />'],
  ['<a class="skip-link" href="#main">Skip to content</a>', '<a class="skip-link" href="#main">{{skip_link}}</a>'],
  ['<li><a href="support/">Support</a></li>', '<li><a href="support/">{{nav_support}}</a></li>'],
  ['<li><a href="privacy/">Privacy</a></li>', '<li><a href="privacy/">{{nav_privacy}}</a></li>'],
  ['alt="Metronome app icon"', 'alt="{{idx_icon_alt}}"'],
  ['<h1>The metronome musicians actually trust.</h1>', '<h1>{{idx_hero_h1}}</h1>'],
  ['<p class="tagline">Sample-accurate timing, pro rhythm tools, and a finish worthy of stage and studio.</p>', '<p class="tagline">{{idx_hero_tagline}}</p>'],
  ['aria-label="Coming soon to the App Store"', 'aria-label="{{idx_cta}}"'],
  ["        Coming soon to the App Store\n", "        {{idx_cta}}\n"],
  ['alt="Metronome app screen showing tempo controls, time signature, and beat indicators"', 'alt="{{idx_screenshot_alt}}"'],
  ['<h2 id="features-h">Built for the click</h2>', '<h2 id="features-h">{{idx_features_h2}}</h2>'],
  ['<p class="section-sub">Designed for working musicians who care about timing — at home, in the studio, and on stage.</p>', '<p class="section-sub">{{idx_features_sub}}</p>'],
  ['<h3>Sample-accurate timing</h3>', '<h3>{{idx_feat1_h}}</h3>'],
  ['<p>Dedicated audio scheduling. No drift. No stutter. No surprises mid-take.</p>', '<p>{{idx_feat1_p}}</p>'],
  ['<h3>Mixed meter &amp; polyrhythms</h3>', '<h3>{{idx_feat2_h}}</h3>'],
  ['<p>Chain 5/8 → 7/8 → 4/4 freely. Layer 3:2, 4:3, 5:4 with multi-bar resolution.</p>', '<p>{{idx_feat2_p}}</p>'],
  ['<h3>Human Feel</h3>', '<h3>{{idx_feat3_h}}</h3>'],
  ['<p>Subtle micro-timing variation that breathes like a real drummer — not a grid.</p>', '<p>{{idx_feat3_p}}</p>'],
  ['<h3>MIDI Clock &amp; Ableton Link</h3>', '<h3>{{idx_feat4_h}}</h3>'],
  ['<p>Sync with hardware, apps, and other devices. Production-ready in studio or on stage.</p>', '<p>{{idx_feat4_p}}</p>'],
  ['<h3>Apple Watch &amp; Live Activities</h3>', '<h3>{{idx_feat5_h}}</h3>'],
  ['<p>Control playback from your wrist. Glance at tempo from the Lock Screen.</p>', '<p>{{idx_feat5_p}}</p>'],
  ['<h3>11 hand-crafted themes</h3>', '<h3>{{idx_feat6_h}}</h3>'],
  ['<p>Five dark, five light, plus System. Stage Mode for dim venues. Custom click sounds.</p>', '<p>{{idx_feat6_p}}</p>'],
  ['<div>© 2026 Whitespace Studio. Made for working musicians.</div>', '<div>© 2026 Whitespace Studio. {{footer_madefor}}</div>'],
]

SUPPORT_REPLS = [
  ['<html lang="en">', '<html lang="{{LANG}}"{{DIRATTR}}>'],
  ['<title>Support — Metronome</title>', '<title>{{sup_title}}</title>'],
  ['<meta name="description" content="Help, contact, and FAQ for the Metronome iOS app." />', '<meta name="description" content="{{sup_meta_desc}}" />'],
  ['<link rel="canonical" href="https://juanca-jimi.github.io/metronome/support/" />', '<link rel="canonical" href="{{CANON}}" />'],
  ['<meta property="og:title" content="Support — Metronome" />', '<meta property="og:title" content="{{sup_title}}" />'],
  ['<meta property="og:description" content="Help, contact, and FAQ for the Metronome iOS app." />', '<meta property="og:description" content="{{sup_meta_desc}}" />'],
  ['<meta property="og:url" content="https://juanca-jimi.github.io/metronome/support/" />', '<meta property="og:url" content="{{CANON}}" />'],
  ['<a class="skip-link" href="#main">Skip to content</a>', '<a class="skip-link" href="#main">{{skip_link}}</a>'],
  ['<li><a href="./" aria-current="page">Support</a></li>', '<li><a href="./" aria-current="page">{{nav_support}}</a></li>'],
  ['<li><a href="../privacy/">Privacy</a></li>', '<li><a href="../privacy/">{{nav_privacy}}</a></li>'],
  ['<h1>Support</h1>', '<h1>{{sup_h1}}</h1>'],
  ['<p class="tagline">Help, contact, and answers for working musicians.</p>', '<p class="tagline">{{sup_tagline}}</p>'],
  ['<h2>Contact</h2>', '<h2>{{sup_contact_h2}}</h2>'],
  ['<p>For bug reports, feature requests, or anything else, email us:</p>', '<p>{{sup_contact_intro}}</p>'],
  ['<p>We aim to reply within 2 business days.</p>', '<p>{{sup_contact_reply}}</p>'],
  ['<h2>Frequently asked</h2>', '<h2>{{sup_faq_h2}}</h2>'],
  ['<dt>The click feels late or early — even after calibration.</dt>', '<dt>{{sup_faq1_q}}</dt>'],
  ['<dd>Bluetooth headphones add 150–300 ms via codec, and the value drifts with battery and proximity. After running <code>All Settings → Latency Calibration</code>, also disable spatial audio and any EQ presets on your headphones — those layer additional latency on top.</dd>', '<dd>{{sup_faq1_a}}</dd>'],
  ['<dt>How is Human Feel different from a swing percentage?</dt>', '<dt>{{sup_faq2_q}}</dt>'],
  ["<dd>Swing skews subdivisions in a fixed pattern (long-short, long-short). Human Feel adds randomized micro-timing variation across all subdivisions, weighted so downbeats stay rock-solid while off-beats breathe. The strength slider controls how much — at 100%, it's roughly what a session drummer adds without thinking about it.</dd>", '<dd>{{sup_faq2_a}}</dd>'],
  ['<dt>Does Ableton Link sync count-ins?</dt>', '<dt>{{sup_faq3_q}}</dt>'],
  ["<dd>Link only transmits beat phase and tempo, not count-ins. If Metronome is the Link source, your DAW joins on the next beat boundary; if the DAW is the source, Metronome's count-in plays locally before beat 1.</dd>", '<dd>{{sup_faq3_a}}</dd>'],
  ['<dt>Can I import custom click sounds?</dt>', '<dt>{{sup_faq4_q}}</dt>'],
  ["<dd>Yes — drop a 16-bit stereo WAV at 44.1 kHz with minimal leading silence (≤1 ms) into Metronome's folder via the Files app, then assign it in Sound Library. Other formats will play, but extra leading silence will shift the perceived downbeat.</dd>", '<dd>{{sup_faq4_a}}</dd>'],
  ['<dt>How do I unlock Mixed Meter, Polyrhythm, or Human Feel?</dt>', '<dt>{{sup_faq5_q}}</dt>'],
  ["<dd>One-time Pro purchase. No subscription. Tap any locked feature for the upgrade sheet, or <code>Restore Purchases</code> if you've bought it before.</dd>", '<dd>{{sup_faq5_a}}</dd>'],
  ['<dt>How do I delete all my data?</dt>', '<dt>{{sup_faq6_q}}</dt>'],
  ['<dd><code>All Settings → Delete All Data</code>. Wipes practice log, streaks, goals, setlists, and imported sounds. Immediate and irreversible.</dd>', '<dd>{{sup_faq6_a}}</dd>'],
  ['<dt>Can I bind volume buttons to BPM?</dt>', '<dt>{{sup_faq7_q}}</dt>'],
  ["<dd>Yes — <code>All Settings → BPM Controls → Volume Buttons = BPM</code>. Off by default so it doesn't override normal volume behavior unexpectedly. While enabled, ringer volume is unaffected.</dd>", '<dd>{{sup_faq7_a}}</dd>'],
  ["<dt>MIDI Clock or Ableton Link won't connect.</dt>", '<dt>{{sup_faq8_q}}</dt>'],
  ['<dd>Both need local-network and Bluetooth permissions in <code>iOS Settings → Metronome</code>. Link also requires all devices to be on the same Wi-Fi network — and the same VLAN, if your router uses guest-network isolation.</dd>', '<dd>{{sup_faq8_a}}</dd>'],
  ['<h2>Privacy</h2>', '<h2>{{sup_privacy_h2}}</h2>'],
  ['<p>Metronome does not collect, sell, or share your personal data. The app stores your settings, practice log, and setlists on your device only. Optional iCloud sync uses your private Apple iCloud account — the developer and any third party have no access.</p>', '<p>{{sup_privacy_p1}}</p>'],
  ['<p>Microphone access is used only by the built-in tuner to detect pitch in real time; audio is processed on-device and never recorded or transmitted.</p>', '<p>{{sup_privacy_p2}}</p>'],
  ['<a href="../privacy/">Read the full privacy policy →</a>', '<a href="../privacy/">{{sup_privacy_link}}</a>'],
  ['<li><a href="../">Home</a></li>', '<li><a href="../">{{nav_home}}</a></li>'],
  ['<div>© 2026 Whitespace Studio. Made for working musicians.</div>', '<div>© 2026 Whitespace Studio. {{footer_madefor}}</div>'],
]

PRIVACY_REPLS = [
  ['<html lang="en">', '<html lang="{{LANG}}"{{DIRATTR}}>'],
  ['<title>Privacy Policy — Metronome</title>', '<title>{{priv_title}}</title>'],
  ["<meta name=\"description\" content=\"Privacy policy for the Metronome iOS app — what we don't collect, what stays on your device, and how to reach us.\" />", '<meta name="description" content="{{priv_meta_desc}}" />'],
  ['<link rel="canonical" href="https://juanca-jimi.github.io/metronome/privacy/" />', '<link rel="canonical" href="{{CANON}}" />'],
  ['<meta property="og:title" content="Privacy Policy — Metronome" />', '<meta property="og:title" content="{{priv_title}}" />'],
  ["<meta property=\"og:description\" content=\"Privacy policy for the Metronome iOS app — what we don't collect, what stays on your device, and how to reach us.\" />", '<meta property="og:description" content="{{priv_meta_desc}}" />'],
  ['<meta property="og:url" content="https://juanca-jimi.github.io/metronome/privacy/" />', '<meta property="og:url" content="{{CANON}}" />'],
  ['<a class="skip-link" href="#main">Skip to content</a>', '<a class="skip-link" href="#main">{{skip_link}}</a>'],
  ['<li><a href="../support/">Support</a></li>', '<li><a href="../support/">{{nav_support}}</a></li>'],
  ['<li><a href="./" aria-current="page">Privacy</a></li>', '<li><a href="./" aria-current="page">{{nav_privacy}}</a></li>'],
  ['<h1>Privacy Policy</h1>', '<h1>{{priv_h1}}</h1>'],
  ['<p class="last-updated">Last updated: April 27, 2026</p>', '<p class="last-updated">{{priv_last_updated}}</p>'],
  ['<h2>The short version</h2>', '<h2>{{priv_summary_h2}}</h2>'],
  ['<p>Metronome does not collect, store, or share your personal data on any server. There is no account system, no analytics, no advertising, and no third-party tracking. Everything you do in the app stays on your device.</p>', '<p>{{priv_summary_p}}</p>'],
  ["<h2>1. Information we don't collect</h2>", '<h2>{{priv_s1_h2}}</h2>'],
  ['<p>Metronome does not collect any of the following:</p>', '<p>{{priv_s1_intro}}</p>'],
  ['<li>Personal identifiers (name, email, phone number, account ID)</li>', '<li>{{priv_s1_li1}}</li>'],
  ['<li>Device identifiers used for tracking (IDFA, IDFV)</li>', '<li>{{priv_s1_li2}}</li>'],
  ['<li>Location data</li>', '<li>{{priv_s1_li3}}</li>'],
  ['<li>Usage analytics or session data</li>', '<li>{{priv_s1_li4}}</li>'],
  ['<li>Crash reports beyond the anonymous reports Apple provides via TestFlight or App Analytics, which you can opt out of in iOS Settings</li>', '<li>{{priv_s1_li5}}</li>'],
  ['<li>Audio recordings, MIDI data, or any media content</li>', '<li>{{priv_s1_li6}}</li>'],
  ['<h2>2. Information stored on your device</h2>', '<h2>{{priv_s2_h2}}</h2>'],
  ['<p>The app stores the following locally on your iPhone, iPad, or Apple Watch. None of this leaves the device unless you explicitly enable iCloud sync (see Section 4):</p>', '<p>{{priv_s2_intro}}</p>'],
  ['<li>App settings (selected theme, sounds, latency calibration, BPM, time signature)</li>', '<li>{{priv_s2_li1}}</li>'],
  ['<li>Practice log entries (date, duration, tempo)</li>', '<li>{{priv_s2_li2}}</li>'],
  ['<li>Streak and goal-tempo tracking</li>', '<li>{{priv_s2_li3}}</li>'],
  ['<li>Setlists you create</li>', '<li>{{priv_s2_li4}}</li>'],
  ['<li>Custom click sounds you import</li>', '<li>{{priv_s2_li5}}</li>'],
  ['<p>You can delete all of this data at any time from <strong>All Settings → Delete All Data</strong>. The deletion is immediate and cannot be undone.</p>', '<p>{{priv_s2_delete}}</p>'],
  ['<h2>3. Permissions we request</h2>', '<h2>{{priv_s3_h2}}</h2>'],
  ['<h3>Microphone</h3>', '<h3>{{priv_s3_mic_h3}}</h3>'],
  ['<p>Used by the built-in tuner to detect the pitch of your instrument in real time. Audio is analyzed on-device and discarded immediately — nothing is recorded, stored, or transmitted. The microphone is only active while the tuner screen is open.</p>', '<p>{{priv_s3_mic_p}}</p>'],
  ['<h3>Bluetooth</h3>', '<h3>{{priv_s3_bt_h3}}</h3>'],
  ['<p>Used to connect to Bluetooth MIDI devices for clock output and external control. Metronome does not scan for or connect to non-MIDI Bluetooth devices.</p>', '<p>{{priv_s3_bt_p}}</p>'],
  ['<h3>Local Network</h3>', '<h3>{{priv_s3_ln_h3}}</h3>'],
  ['<p>Used by Ableton Link to discover and sync tempo with other music apps and devices on the same Wi-Fi network. Metronome does not transmit any data to the public internet via this permission.</p>', '<p>{{priv_s3_ln_p}}</p>'],
  ['<h2>4. iCloud sync (optional)</h2>', '<h2>{{priv_s4_h2}}</h2>'],
  ["<p>If you enable iCloud sync, your setlists, practice log, and settings are synchronized across your own Apple devices using Apple's iCloud infrastructure. The data is end-to-end encrypted by Apple and is associated with your private Apple ID. The developer of Metronome cannot access this data, and no third party is involved. If you disable iCloud sync, the data remains on the device where you created it.</p>", '<p>{{priv_s4_p}}</p>'],
  ['<h2>5. In-app purchases</h2>', '<h2>{{priv_s5_h2}}</h2>'],
  ["<p>Pro features and tip-jar purchases are handled by Apple's StoreKit. Apple processes the transaction; the developer receives only the standard receipt (anonymous purchase confirmation). Metronome does not see your payment details, name, or Apple ID.</p>", '<p>{{priv_s5_p}}</p>'],
  ["<h2>6. Children's privacy</h2>", '<h2>{{priv_s6_h2}}</h2>'],
  ['<p>Metronome is suitable for users of all ages and does not knowingly collect any data from children under 13. Because the app does not collect any personal data from any user, no special children\'s data flow exists.</p>', '<p>{{priv_s6_p}}</p>'],
  ['<h2>7. Changes to this policy</h2>', '<h2>{{priv_s7_h2}}</h2>'],
  ['<p>If this policy changes in a meaningful way, the "Last updated" date at the top will be revised and a summary of the change will be added to a new section here. Continued use of the app after a policy change constitutes acceptance of the updated policy.</p>', '<p>{{priv_s7_p}}</p>'],
  ['<h2>8. Contact</h2>', '<h2>{{priv_s8_h2}}</h2>'],
  ['<p>Questions about privacy? Email <a href="mailto:juancajimi@icloud.com?subject=Metronome%20privacy%20question">juancajimi@icloud.com</a>. We aim to reply within 2 business days.</p>', '<p>{{priv_s8_p_before}} <a href="mailto:juancajimi@icloud.com?subject=Metronome%20privacy%20question">juancajimi@icloud.com</a>{{priv_s8_p_after}}</p>'],
  ['<li><a href="../">Home</a></li>', '<li><a href="../">{{nav_home}}</a></li>'],
  ['<div>© 2026 Whitespace Studio. Made for working musicians.</div>', '<div>© 2026 Whitespace Studio. {{footer_madefor}}</div>'],
]

# Read the real pages (must exist at repo root).
idx_tmpl  = templatize(File.read("#{ROOT}/index.html"),         INDEX_REPLS,   "index")
sup_tmpl  = templatize(File.read("#{ROOT}/support/index.html"), SUPPORT_REPLS, "support")
priv_tmpl = templatize(File.read("#{ROOT}/privacy/index.html"), PRIVACY_REPLS, "privacy")

# Fix asset-path depth: root page uses "assets/…" -> "../assets/…";
# support/privacy already use "../assets/…" -> need "../../assets/…".
idx_tmpl  = idx_tmpl.gsub('"assets/', '"../assets/')
sup_tmpl  = sup_tmpl.gsub('"../assets/', '"../../assets/')
priv_tmpl = priv_tmpl.gsub('"../assets/', '"../../assets/')

def render(tmpl, tr, lang, dir_rtl, canon)
  out = tmpl.dup
  out = out.gsub("{{LANG}}", lang)
  out = out.gsub("{{DIRATTR}}", dir_rtl ? ' dir="rtl"' : "")
  out = out.gsub("{{CANON}}", canon)
  tr.each { |k, v| out = out.gsub("{{#{k}}}", v) }
  leftover = out.scan(/\{\{[a-z0-9_]+\}\}/i).uniq
  raise "unfilled placeholders: #{leftover.join(', ')}" unless leftover.empty?
  out
end

slugs = TRANSLATED.keys + FALLBACK
count = 0
slugs.each do |slug|
  translated = TRANSLATED.key?(slug)
  lang = TRANSLATED[slug] || "en"
  file = translated ? "#{ROOT}/i18n/#{slug}.json" : "#{ROOT}/i18n/en.json"
  tr = load_tr(file, EN)
  rtl = RTL.include?(slug)

  # Translated pages are unique content -> self-canonical.
  # English-fallback pages are copies of the English root -> canonical to the root,
  # so search engines consolidate them instead of seeing 37 duplicates.
  cbase = translated ? "#{BASE}/#{slug}" : BASE

  dir = "#{ROOT}/#{slug}"
  Dir.mkdir(dir) unless Dir.exist?(dir)
  Dir.mkdir("#{dir}/support") unless Dir.exist?("#{dir}/support")
  Dir.mkdir("#{dir}/privacy") unless Dir.exist?("#{dir}/privacy")

  File.write("#{dir}/index.html",         render(idx_tmpl,  tr, lang, rtl, "#{cbase}/"))
  File.write("#{dir}/support/index.html", render(sup_tmpl,  tr, lang, rtl, "#{cbase}/support/"))
  File.write("#{dir}/privacy/index.html", render(priv_tmpl, tr, lang, rtl, "#{cbase}/privacy/"))
  count += 1
  puts "✓ #{slug} (#{lang})#{rtl ? ' [rtl]' : ''}#{translated ? '' : ' [en-fallback]'}"
end
puts "\nRendered #{count} slug dirs × 3 pages = #{count * 3} files."

# --- Regenerate sitemap.xml with hreflang alternates for the real language versions.
# Only canonical URLs are listed (English root + the 7 translated languages); the
# English-fallback slugs canonical to the root and are intentionally omitted.
require "date"
today = Time.now.strftime("%Y-%m-%d")
PAGES = [["", "1.0", "monthly"], ["support/", "0.7", "monthly"], ["privacy/", "0.5", "yearly"]]
# [hreflang, url-prefix]; "" prefix = English root.
VARIANTS = [["en", ""]] + TRANSLATED.map { |slug, tag| [tag, slug] }
def url_for(pfx, page); pfx.empty? ? "#{BASE}/#{page}" : "#{BASE}/#{pfx}/#{page}"; end

sm = +%(<?xml version="1.0" encoding="UTF-8"?>\n)
sm << %(<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"\n)
sm << %(        xmlns:xhtml="http://www.w3.org/1999/xhtml">\n)
PAGES.each do |page, priority, freq|
  VARIANTS.each do |_tag, pfx|
    sm << "  <url>\n"
    sm << "    <loc>#{url_for(pfx, page)}</loc>\n"
    sm << %(    <xhtml:link rel="alternate" hreflang="x-default" href="#{url_for('', page)}" />\n)
    VARIANTS.each do |tag2, pfx2|
      sm << %(    <xhtml:link rel="alternate" hreflang="#{tag2}" href="#{url_for(pfx2, page)}" />\n)
    end
    sm << "    <lastmod>#{today}</lastmod>\n"
    sm << "    <changefreq>#{freq}</changefreq>\n"
    sm << "    <priority>#{priority}</priority>\n"
    sm << "  </url>\n"
  end
end
sm << "</urlset>\n"
File.write("#{ROOT}/sitemap.xml", sm)
puts "Wrote sitemap.xml (#{PAGES.size * VARIANTS.size} canonical URLs, hreflang-linked)."

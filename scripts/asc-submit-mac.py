#!/usr/bin/env python3
# App Store Connect submission driver for DS Music (macOS / Mac App Store).
# Same app record as iOS (APP_ID below); the macOS appStoreVersion and the
# build are resolved dynamically (no hardcoded IDs) by platform == MAC_OS.
#
# Token is passed via ASC_TOKEN env (minted by scripts/asc-jwt.swift).
# Usage:
#   ASC_TOKEN=$(ASC_KEY_ID=.. ASC_ISSUER_ID=.. swift scripts/asc-jwt.swift) \
#     python3 scripts/asc-submit-mac.py <step>
#
# Steps (run roughly in this order after release-mac.sh finishes processing):
#   status            show the macOS version + attached build
#   version-and-build set versionString=0.2.0, attach newest valid mac build
#   metadata          description / keywords / promo / URLs
#   review-detail <phone>   App Review contact + demo Audio Station account
#   age-rating        4+ declaration
#   category          primary category = MUSIC
#   fix-required      copyright / content rights / privacy URL
#   submit-state      readiness snapshot
#   clean-submissions delete empty/READY macOS review submissions
#   submit            create reviewSubmission + add version + SUBMIT
import json, os, sys, urllib.request, urllib.error

BASE = "https://api.appstoreconnect.apple.com/v1"
TOK = os.environ["ASC_TOKEN"]
APP_ID = "6770202629"          # same app record as iOS
PLATFORM = "MAC_OS"
VERSION_STRING = "0.2.0"

def req(method, path, body=None):
    url = path if path.startswith("http") else f"{BASE}/{path}"
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(url, data=data, method=method)
    r.add_header("Authorization", f"Bearer {TOK}")
    r.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(r) as resp:
            t = resp.read().decode()
            return resp.status, (json.loads(t) if t else {})
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read().decode() or "{}")

def show(tag, st, body):
    ok = 200 <= st < 300
    print(f"[{ 'OK' if ok else 'ERR' } {st}] {tag}")
    if not ok:
        print("   ", json.dumps(body.get("errors", body))[:600])
    return ok

def mac_version_id():
    """The editable macOS appStoreVersion for this app."""
    st, b = req("GET", f"apps/{APP_ID}/appStoreVersions"
                f"?filter%5Bplatform%5D={PLATFORM}&limit=50")
    vs = b.get("data", [])
    # Prefer an editable state; otherwise the newest.
    editable = {"PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED",
                "REJECTED", "METADATA_REJECTED", "INVALID_BINARY"}
    for v in vs:
        if v["attributes"].get("appStoreState") in editable:
            return v["id"]
    if vs:
        return vs[0]["id"]
    sys.exit("no macOS appStoreVersion found — add the macOS platform "
             "to the app in App Store Connect first")

def newest_mac_build():
    """Newest VALID build whose pre-release version is macOS."""
    st, b = req("GET", f"builds?filter%5Bapp%5D={APP_ID}"
                "&sort=-uploadedDate&limit=30&include=preReleaseVersion")
    inc = {i["id"]: i for i in b.get("included", [])}
    for bd in b.get("data", []):
        pv = bd.get("relationships", {}).get("preReleaseVersion", {}) \
               .get("data")
        plat = inc.get(pv["id"], {}).get("attributes", {}).get("platform") \
            if pv else None
        if plat == PLATFORM and \
           bd["attributes"].get("processingState") == "VALID":
            return bd["id"], bd["attributes"].get("version")
    return None, None

step = sys.argv[1] if len(sys.argv) > 1 else "status"
VER_ID = None
if step not in ("clean-submissions",):
    VER_ID = mac_version_id()

if step == "status":
    st, b = req("GET", f"appStoreVersions/{VER_ID}"
                "?include=build,appStoreVersionLocalizations")
    print(json.dumps(b, indent=2)[:1500])

elif step == "version-and-build":
    st, b = req("PATCH", f"appStoreVersions/{VER_ID}", {
        "data": {"type": "appStoreVersions", "id": VER_ID,
                 "attributes": {"versionString": VERSION_STRING,
                                "releaseType": "MANUAL"}}})
    show(f"set versionString={VERSION_STRING}", st, b)
    bid, bno = newest_mac_build()
    if not bid:
        sys.exit("no VALID macOS build yet — wait for ASC processing")
    st, b = req("PATCH", f"appStoreVersions/{VER_ID}/relationships/build", {
        "data": {"type": "builds", "id": bid}})
    show(f"attach build {bno}", st, b)

elif step == "metadata":
    st, b = req("GET", f"appStoreVersions/{VER_ID}/appStoreVersionLocalizations")
    locs = b.get("data", [])
    print("locales:", [l["attributes"]["locale"] for l in locs])
    desc = ("DS Music is a clean, native client for your own Synology Audio "
            "Station. It is not a streaming service and has no catalog of its "
            "own — it plays the music on a Synology NAS that you control.\n\n"
            "• Browse by Artists, Albums and Playlists, or search your "
            "whole library\n"
            "• Apple Music–style now playing with full-screen artwork "
            "and scrubbing\n"
            "• Background and lock-screen playback, AirPlay output\n"
            "• Lives in the menu bar; media keys and Now Playing controls\n"
            "• Lossless streaming from your server\n"
            "• No account, no ads, no tracking — your music and "
            "credentials stay on your devices and your own NAS\n\n"
            "Requires a Synology NAS running Audio Station.")
    attrs = {
        "description": desc,
        "keywords": "synology,audio station,nas,music,player,dsm,diskstation,streaming,flac,quickconnect,library",
        "promotionalText": ("A fast, native player for your own Synology Audio "
            "Station — browse, search and stream your library with an "
            "Apple Music–style interface."),
        "supportUrl": "https://dsplay-demo.hillsdong.workers.dev/support",
        "marketingUrl": "https://dsplay-demo.hillsdong.workers.dev",
    }
    for l in locs:
        lid = l["id"]
        st, bd = req("PATCH", f"appStoreVersionLocalizations/{lid}", {
            "data": {"type": "appStoreVersionLocalizations", "id": lid,
                     "attributes": attrs}})
        show(f"localization {l['attributes']['locale']}", st, bd)

elif step == "review-detail":
    phone = sys.argv[2]
    st, b = req("GET", f"appStoreVersions/{VER_ID}/appStoreReviewDetail")
    body = {"type": "appStoreReviewDetails",
            "attributes": {
                "contactFirstName": "Qifeng", "contactLastName": "Dong",
                "contactEmail": "hillsdong.sg@gmail.com",
                "contactPhone": phone,
                "demoAccountName": "applereview",
                "demoAccountPassword": "demo",
                "demoAccountRequired": True,
                "notes": ("DS Music is a client for a self-hosted Synology "
                  "Audio Station (like Synology's own DS audio); it has no "
                  "catalog of its own. For review a demo Audio Station server "
                  "is hosted. On the first screen enter Server "
                  "https://dsplay-demo.hillsdong.workers.dev, Username "
                  "applereview, Password demo, click Connect, then browse "
                  "Artists/Albums/Playlists/Search and click any track to "
                  "play. The app lives in the menu bar; background and "
                  "media-key playback are supported.")}}
    if b.get("data"):
        rid = b["data"]["id"]; body["id"] = rid
        st, bd = req("PATCH", f"appStoreReviewDetails/{rid}", {"data": body})
        show("patch review detail", st, bd)
    else:
        body["relationships"] = {"appStoreVersion": {"data": {
            "type": "appStoreVersions", "id": VER_ID}}}
        st, bd = req("POST", "appStoreReviewDetails", {"data": body})
        show("create review detail", st, bd)

elif step == "age-rating":
    st, b = req("GET", f"apps/{APP_ID}/appInfos")
    for ai in b.get("data", []):
        aid = ai["id"]
        st2, b2 = req("GET", f"appInfos/{aid}/ageRatingDeclaration")
        d = b2.get("data")
        if not d:
            continue
        rid = d["id"]
        st3, b3 = req("PATCH", f"ageRatingDeclarations/{rid}", {
            "data": {"type": "ageRatingDeclarations", "id": rid,
              "attributes": {
                "advertising": False,
                "ageAssurance": False,
                "alcoholTobaccoOrDrugUseOrReferences": "NONE",
                "contests": "NONE",
                "gambling": False,
                "gamblingSimulated": "NONE",
                "gunsOrOtherWeapons": "NONE",
                "healthOrWellnessTopics": False,
                "lootBox": False,
                "medicalOrTreatmentInformation": "NONE",
                "messagingAndChat": False,
                "parentalControls": False,
                "profanityOrCrudeHumor": "NONE",
                "sexualContentGraphicAndNudity": "NONE",
                "sexualContentOrNudity": "NONE",
                "horrorOrFearThemes": "NONE",
                "matureOrSuggestiveThemes": "NONE",
                "unrestrictedWebAccess": False,
                "userGeneratedContent": False,
                "violenceCartoonOrFantasy": "NONE",
                "violenceRealisticProlongedGraphicOrSadistic": "NONE",
                "violenceRealistic": "NONE",
                "kidsAgeBand": None}}})
        show(f"age rating ({aid})", st3, b3)

elif step == "upload-screenshots":
    import hashlib
    LOC = None
    st, b = req("GET", f"appStoreVersions/{VER_ID}/appStoreVersionLocalizations")
    for l in b.get("data", []):
        if l["attributes"]["locale"] == "en-US":
            LOC = l["id"]
    print("localization:", LOC)
    # Mac App Store screenshot display types: 16:10 desktop sizes.
    GROUPS = {
        "APP_DESKTOP": ["/tmp/ds/shot_mac_albums.png",
                        "/tmp/ds/shot_mac_detail.png",
                        "/tmp/ds/shot_mac_now.png"],
    }
    st, b = req("GET", f"appStoreVersionLocalizations/{LOC}/appScreenshotSets")
    sets = {s["attributes"]["screenshotDisplayType"]: s["id"]
            for s in b.get("data", [])}
    for dtype, files in GROUPS.items():
        sid = sets.get(dtype)
        if not sid:
            st, b = req("POST", "appScreenshotSets", {"data": {
                "type": "appScreenshotSets",
                "attributes": {"screenshotDisplayType": dtype},
                "relationships": {"appStoreVersionLocalization": {"data": {
                    "type": "appStoreVersionLocalizations", "id": LOC}}}}})
            if not show(f"create set {dtype}", st, b):
                continue
            sid = b["data"]["id"]
        st, ex = req("GET", f"appScreenshotSets/{sid}/appScreenshots")
        if ex.get("data"):
            print(f"  set {dtype} already has {len(ex['data'])} — skip")
            continue
        for fp in files:
            data = open(fp, "rb").read()
            fn = os.path.basename(fp)
            st, b = req("POST", "appScreenshots", {"data": {
                "type": "appScreenshots",
                "attributes": {"fileSize": len(data), "fileName": fn},
                "relationships": {"appScreenshotSet": {"data": {
                    "type": "appScreenshotSets", "id": sid}}}}})
            if not show(f"reserve {fn}", st, b):
                continue
            ssid = b["data"]["id"]
            for op in b["data"]["attributes"]["uploadOperations"]:
                chunk = data[op["offset"]:op["offset"] + op["length"]]
                r = urllib.request.Request(op["url"], data=chunk,
                                           method=op["method"])
                for h in op["requestHeaders"]:
                    r.add_header(h["name"], h["value"])
                try:
                    urllib.request.urlopen(r)
                except urllib.error.HTTPError as e:
                    print("   upload chunk err", e.code, e.read()[:200]); break
            md5 = hashlib.md5(data).hexdigest()
            st, b = req("PATCH", f"appScreenshots/{ssid}", {"data": {
                "type": "appScreenshots", "id": ssid,
                "attributes": {"uploaded": True, "sourceFileChecksum": md5}}})
            show(f"commit {fn}", st, b)

elif step == "category":
    st, b = req("GET", f"apps/{APP_ID}/appInfos")
    for ai in b.get("data", []):
        aid = ai["id"]
        st2, b2 = req("PATCH", f"appInfos/{aid}", {
            "data": {"type": "appInfos", "id": aid,
              "relationships": {"primaryCategory": {"data": {
                "type": "appCategories", "id": "MUSIC"}}}}})
        show(f"primary category=MUSIC ({aid})", st2, b2)

elif step == "submit-state":
    st, b = req("GET", f"appStoreVersions/{VER_ID}?include=build,"
                "appStoreReviewDetail,appStoreVersionLocalizations")
    v = b.get("data", {}).get("attributes", {})
    print("version:", v.get("versionString"), v.get("appStoreState"))
    print("has build:", any(i["type"] == "builds"
                            for i in b.get("included", [])))
    print("has reviewDetail:", any(i["type"] == "appStoreReviewDetails"
                                   for i in b.get("included", [])))
    st, sc = req("GET", f"appStoreVersions/{VER_ID}/appStoreVersionLocalizations")
    for l in sc.get("data", []):
        lid, loc = l["id"], l["attributes"]["locale"]
        st2, ss = req("GET", f"appStoreVersionLocalizations/{lid}/appScreenshotSets")
        print(f"  {loc} screenshot sets:",
              [(s['attributes']['screenshotDisplayType'],
                len(s.get('relationships',{}).get('appScreenshots',{})
                     .get('data',[]) or []))
               for s in ss.get("data", [])] or "none")

elif step == "fix-required":
    st, b = req("PATCH", f"appStoreVersions/{VER_ID}", {"data": {
        "type": "appStoreVersions", "id": VER_ID,
        "attributes": {"copyright": "2026 Qifeng Dong"}}})
    show("version copyright", st, b)
    st, b = req("PATCH", f"apps/{APP_ID}", {"data": {
        "type": "apps", "id": APP_ID,
        "attributes": {"contentRightsDeclaration":
                       "DOES_NOT_USE_THIRD_PARTY_CONTENT"}}})
    show("contentRightsDeclaration", st, b)
    st, b = req("GET", f"apps/{APP_ID}/appInfos")
    for ai in b.get("data", []):
        st2, b2 = req("GET", f"appInfos/{ai['id']}/appInfoLocalizations")
        for l in b2.get("data", []):
            lid = l["id"]
            st3, b3 = req("PATCH", f"appInfoLocalizations/{lid}", {"data": {
                "type": "appInfoLocalizations", "id": lid,
                "attributes": {"privacyPolicyUrl":
                    "https://dsplay-demo.hillsdong.workers.dev/privacy"}}})
            show(f"privacyPolicyUrl {l['attributes'].get('locale')}", st3, b3)

elif step == "clean-submissions":
    st, b = req("GET", f"apps/{APP_ID}/reviewSubmissions"
                f"?filter%5Bplatform%5D={PLATFORM}")
    for r in b.get("data", []):
        sstate = r["attributes"]["state"]
        if sstate in ("READY_FOR_REVIEW", "CREATED") or sstate is None:
            st2, _ = req("DELETE", f"reviewSubmissions/{r['id']}")
            print(f"deleted submission {r['id']} ({sstate}) -> {st2}")
        else:
            print(f"kept {r['id']} ({sstate})")

elif step == "submit":
    st, b = req("GET", f"apps/{APP_ID}/reviewSubmissions"
                f"?filter%5Bplatform%5D={PLATFORM}"
                "&filter%5Bstate%5D=READY_FOR_REVIEW,WAITING_FOR_REVIEW,"
                "IN_REVIEW,UNRESOLVED_ISSUES,COMPLETE,CANCELING")
    rs = None
    for r in b.get("data", []):
        if r["attributes"]["state"] in ("READY_FOR_REVIEW",):
            rs = r["id"]
    if not rs:
        st, b = req("POST", "reviewSubmissions", {"data": {
            "type": "reviewSubmissions",
            "attributes": {"platform": PLATFORM},
            "relationships": {"app": {"data": {"type": "apps",
                                               "id": APP_ID}}}}})
        if not show("create reviewSubmission", st, b):
            print(json.dumps(b)[:800]); sys.exit(1)
        rs = b["data"]["id"]
    print("reviewSubmission:", rs)
    st, b = req("POST", "reviewSubmissionItems", {"data": {
        "type": "reviewSubmissionItems",
        "relationships": {
            "reviewSubmission": {"data": {"type": "reviewSubmissions",
                                          "id": rs}},
            "appStoreVersion": {"data": {"type": "appStoreVersions",
                                         "id": VER_ID}}}}})
    show("add version item", st, b)
    st, b = req("PATCH", f"reviewSubmissions/{rs}", {"data": {
        "type": "reviewSubmissions", "id": rs,
        "attributes": {"submitted": True}}})
    if show("SUBMIT FOR REVIEW", st, b):
        print(">>> Submitted. State:",
              b.get("data", {}).get("attributes", {}).get("state"))

else:
    print("unknown step")

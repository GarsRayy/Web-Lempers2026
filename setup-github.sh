#!/usr/bin/env bash
# setup-github.sh — membuat label, milestone, issue (+ assignee per role), dan GitHub Project dari backlog.yml
#
# Idempotent: aman dijalankan ulang. Yang sudah ada dilewati; yang baru ditambahkan.
# Tidak pernah menghapus atau mengubah isi issue yang sudah ada.
# Assignee: diambil dari bagian 'assignees' di backlog.yml (role -> username GitHub); kosong = dilewati.
#
# Pemakaian:  ./setup-github.sh --dry-run     (lihat dulu, tidak mengubah apa pun)
#             ./setup-github.sh               (jalankan sungguhan)
#             ./setup-github.sh --only assign (isi assignee issue yang sudah ada & belum punya assignee)
#
# Prasyarat: bash 3.2+, gh (GitHub CLI), jq, yq v4 (mikefarah). Lihat SETUP.md.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKLOG="$SCRIPT_DIR/backlog.yml"
DRY=0
REPO=""
ONLY="labels,milestones,issues,project"
SLEEP="${SLEEP:-1}"   # jeda (detik) antar pembuatan issue, menghindari secondary rate limit

usage() {
  cat <<'EOF'
Pemakaian: ./setup-github.sh [opsi]

  --dry-run           tampilkan rencana tanpa mengubah apa pun
  --repo OWNER/REPO   timpa repo yang tertulis di backlog.yml
  --backlog FILE      file sumber (default: backlog.yml di folder skrip)
  --only LANGKAH      daftar dipisah koma: labels,milestones,issues,project,assign
                      (default: labels,milestones,issues,project; 'assign' hanya bila diminta)
  -h, --help          bantuan ini

Variabel lingkungan: SLEEP=detik jeda antar issue (default 1).
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1; shift ;;
    --repo)    [ $# -ge 2 ] || { echo "ERROR: --repo butuh nilai" >&2; exit 1; }; REPO="$2"; shift 2 ;;
    --backlog) [ $# -ge 2 ] || { echo "ERROR: --backlog butuh nilai" >&2; exit 1; }; BACKLOG="$2"; shift 2 ;;
    --only)    [ $# -ge 2 ] || { echo "ERROR: --only butuh nilai" >&2; exit 1; }; ONLY="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Opsi tidak dikenal: $1" >&2; usage >&2; exit 1 ;;
  esac
done

# ---------- util ----------
log()  { printf '%s\n' "$*"; }
info() { printf '\n\033[36m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[33m! %s\033[0m\n' "$*" >&2; }
die()  { printf '\033[31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }
want() { case ",$ONLY," in *",$1,"*) return 0 ;; *) return 1 ;; esac; }

# act "pesan" perintah...  -> dry-run: hanya cetak; nyata: cetak lalu jalankan (output dibuang)
act() {
  local msg="$1"; shift
  if [ "$DRY" = 1 ]; then
    printf '  [dry-run] %s\n' "$msg"
  else
    printf '  %s\n' "$msg"
    "$@" </dev/null >/dev/null
  fi
}

need() { command -v "$1" >/dev/null 2>&1 || die "'$1' tidak ditemukan. $2"; }

# ---------- prasyarat ----------
need gh "Pasang GitHub CLI: https://cli.github.com"
need jq "Pasang jq: https://jqlang.github.io/jq"
need yq "Pasang yq v4 (mikefarah): https://github.com/mikefarah/yq"
yq --version 2>&1 | grep -qi mikefarah || die "yq harus versi mikefarah/yq (v4), bukan yq berbasis Python."
[ -f "$BACKLOG" ] || die "File backlog tidak ditemukan: $BACKLOG"

AUTH=0
if gh auth status >/dev/null 2>&1; then AUTH=1; fi
if [ "$AUTH" = 0 ]; then
  [ "$DRY" = 1 ] || die "Belum login. Jalankan: gh auth login   lalu   gh auth refresh -s project"
  warn "Belum login ke gh: dry-run tidak bisa mengecek data yang sudah ada (dianggap kosong)."
fi

DATA="$(yq -o=json '.' "$BACKLOG")" || die "backlog.yml tidak valid (YAML)."
[ -n "$REPO" ] || REPO="$(jq -r '.repo' <<<"$DATA")"
case "$REPO" in */*) ;; *) die "Format repo harus OWNER/REPO, dapat: '$REPO'" ;; esac
OWNER="${REPO%%/*}"

# ---------- ratakan entries -> daftar issue ----------
JQ_FLATTEN=''
read -r -d '' JQ_FLATTEN <<'JQ' || true
def prio_name: {"M":"Must","S":"Should","C":"Could"};
def bullets: map("- [ ] " + .) | join("\n");
(.milestones | map({(.id): .title}) | add) as $mt
| (.assignees // {}) as $asg
| [ .entries[] as $e
    | $e.slices[] as $s
    | (if $s.t == "UI" then "fe" elif $s.t == "Live" then "be" else ($s.r // "") end) as $role
    | (if $s.t == "Full" then "[\($e.id)]" else "[\($e.id)][\($s.t)]" end) as $prefix
    | ($e.slices | length) as $n
    | {
        title: "\($prefix) \($e.title)",
        role: $role,
        assignee: (($asg[$role] // "") | tostring),
        milestone: ($mt[$s.m] // error("milestone '\($s.m)' (di \($e.id)) tidak ada di bagian milestones")),
        points: ($s.p // null),
        prio: (if $e.prio then prio_name[$e.prio] else null end),
        gate: ($s.g // null),
        labels: (
          ["type:\($e.kind)"]
          + (if $e.prio then ["prio:" + (prio_name[$e.prio] | ascii_downcase)] else [] end)
          + (if $e.epic then ["epic:\($e.epic)"] else [] end)
          + (if $s.t == "UI" then ["slice:ui", "role:fe"]
             elif $s.t == "Live" then ["slice:live", "role:be"]
             elif $s.r then ["role:\($s.r)"]
             else [] end)
          + (if $s.g then ["gate:\($s.g)"] else [] end)
          + ($e.labels // [])
        ),
        body: (
            (if $e.story then "**Story:** \($e.story)\n\n" else "" end)
          + (if $e.notes then ($e.notes | rtrimstr("\n")) + "\n\n" else "" end)
          + (if $e.ac then "### Acceptance criteria\n" + ($e.ac | bullets) + "\n\n" else "" end)
          + (if $s.t == "UI" then "**Irisan UI** — tampilan dengan data dummy sesuai kontrak API (Milestone Charter M3).\n\n"
             elif $s.t == "Live" then "**Irisan Live** — terhubung backend/data nyata; selesai bila acceptance criteria lulus dengan data nyata.\n\n"
             else "" end)
          + (if $n > 1 then "_Story ini dipecah per irisan: UI di \($e.slices[0].m), Live di \($e.slices[1].m)._\n\n" else "" end)
          + "**Ref:** \($e.ref // "-") · **Poin irisan ini:** \($s.p // "-") · **Gerbang Charter:** \($s.g // "-")\n\n"
          + "<sub>Sumber: PRD.md & Guide.md · dibuat oleh setup-github.sh</sub>"
        )
      }
  ]
JQ

ISSUES="$(jq -c "$JQ_FLATTEN" <<<"$DATA")" || die "Gagal meratakan backlog (periksa milestone/slices di backlog.yml)."

# validasi: judul issue harus unik
DUP="$(jq -r '[group_by(.title)[] | select(length > 1) | .[0].title] | join("; ")' <<<"$ISSUES")"
[ -z "$DUP" ] || die "Judul issue duplikat di backlog: $DUP"

# ---------- ringkasan rencana ----------
info "Rencana untuk $REPO$( [ "$DRY" = 1 ] && printf '  (DRY-RUN)' )"
log "  Label     : $(jq '.labels | length' <<<"$DATA")"
log "  Milestone : $(jq '.milestones | length' <<<"$DATA")"
log "  Issue     : $(jq 'length' <<<"$ISSUES")   (poin total: $(jq '([.[].points // 0] | add * 10 | round) / 10' <<<"$ISSUES"))"
log "  Project   : $(jq -r '.project.title' <<<"$DATA")  (owner: $OWNER)"
log ""
log "  Beban per milestone (issue | poin):"
jq -r 'group_by(.milestone)[] | "    \(.[0].milestone): \(length) issue | \(([.[].points // 0] | add * 10 | round) / 10) poin"' <<<"$ISSUES"

log ""
log "  Beban per role (issue | poin | assignee):"
jq -r 'group_by(.role)[] | "    \(if .[0].role == "" then "-" else .[0].role end): \(length) issue | \(([.[].points // 0] | add * 10 | round) / 10) poin | \(if .[0].assignee == "" then "(belum diisi)" else .[0].assignee end)"' <<<"$ISSUES"

# ---------- util assignee ----------
ASSIGNABLE=""; ASSIGNABLE_LOADED=0; WARNED=""
load_assignable() {
  if [ "$ASSIGNABLE_LOADED" = 1 ]; then return 0; fi
  ASSIGNABLE_LOADED=1
  if [ "$AUTH" = 1 ]; then
    ASSIGNABLE="$(gh api "repos/$REPO/assignees?per_page=100" --paginate --jq '.[].login' </dev/null 2>/dev/null || true)"
  fi
}
can_assign() {
  local u="$1"
  load_assignable
  if [ "$AUTH" = 0 ]; then return 0; fi
  if grep -Fixq -- "$u" <<<"$ASSIGNABLE"; then return 0; fi
  if ! grep -Fxq -- "$u" <<<"$WARNED"; then
    WARNED="$WARNED"$'\n'"$u"
    warn "'$u' belum menjadi kolaborator repo $REPO (atau tidak bisa di-assign): issue untuk role ini dibuat tanpa assignee."
  fi
  return 1
}

# ---------- langkah 1: label ----------
step_labels() {
  info "Label"
  local l name color desc
  while IFS= read -r l <&3; do
    name="$(jq -r '.name' <<<"$l")"
    color="$(jq -r '.color' <<<"$l")"
    desc="$(jq -r '.desc // ""' <<<"$l")"
    act "label: $name" gh label create "$name" --repo "$REPO" --color "$color" --description "$desc" --force
  done 3< <(jq -c '.labels[]' <<<"$DATA")
}

# ---------- langkah 2: milestone ----------
step_milestones() {
  info "Milestone"
  local existing="" m title due desc
  if [ "$AUTH" = 1 ]; then
    existing="$(gh api "repos/$REPO/milestones?state=all&per_page=100" --paginate --jq '.[].title' </dev/null)"
  fi
  while IFS= read -r m <&3; do
    title="$(jq -r '.title' <<<"$m")"
    due="$(jq -r '.due // empty' <<<"$m")"
    desc="$(jq -r '.desc // ""' <<<"$m")"
    if grep -Fxq -- "$title" <<<"$existing"; then
      log "  = sudah ada: $title"
      continue
    fi
    if [ -n "$due" ]; then
      # 16:59:59Z = 23:59:59 WIB, sehingga tanggal tenggat tetap benar di WIB maupun UTC
      act "milestone: $title (tenggat $due)" gh api "repos/$REPO/milestones" \
        -f "title=$title" -f "state=open" -f "description=$desc" -f "due_on=${due}T16:59:59Z"
    else
      act "milestone: $title (tanpa tenggat)" gh api "repos/$REPO/milestones" \
        -f "title=$title" -f "state=open" -f "description=$desc"
    fi
  done 3< <(jq -c '.milestones[]' <<<"$DATA")
}

# ---------- langkah 3: issue ----------
step_issues() {
  info "Issue"
  local existing_json='[]' i title ms labels body assignee shown created=0 skipped=0
  local -a args
  if [ "$AUTH" = 1 ]; then
    existing_json="$(gh issue list --repo "$REPO" --state all --limit 1000 --json title </dev/null)"
  fi
  while IFS= read -r i <&3; do
    title="$(jq -r '.title' <<<"$i")"
    if jq -e --arg t "$title" 'any(.[]; .title == $t)' <<<"$existing_json" >/dev/null; then
      skipped=$((skipped + 1))
      log "  = sudah ada: $title"
      continue
    fi
    ms="$(jq -r '.milestone' <<<"$i")"
    labels="$(jq -r '.labels | join(",")' <<<"$i")"
    body="$(jq -r '.body' <<<"$i")"
    assignee="$(jq -r '.assignee' <<<"$i")"
    args=(--repo "$REPO" --title "$title" --body "$body" --label "$labels" --milestone "$ms")
    shown=""
    if [ -n "$assignee" ] && can_assign "$assignee"; then
      args+=(--assignee "$assignee"); shown=" -> @$assignee"
    fi
    act "issue: $title  [$ms | $labels]$shown" gh issue create "${args[@]}"
    created=$((created + 1))
    if [ "$DRY" = 0 ]; then sleep "$SLEEP"; fi
  done 3< <(jq -c '.[]' <<<"$ISSUES")
  log ""
  log "  Issue baru: $created · dilewati (sudah ada): $skipped"
}

# ---------- langkah 3b: assignee untuk issue yang sudah ada ----------
step_assign() {
  info "Assignee"
  if [ "$AUTH" = 0 ]; then warn "Belum login ke gh: langkah assign dilewati."; return 0; fi
  local existing i title user num n=0
  existing="$(gh issue list --repo "$REPO" --state all --limit 1000 --json number,title,assignees </dev/null)"
  while IFS= read -r i <&3; do
    title="$(jq -r '.title' <<<"$i")"
    user="$(jq -r '.assignee' <<<"$i")"
    if [ -z "$user" ]; then continue; fi
    num="$(jq -r --arg t "$title" '[.[] | select(.title == $t)][0] | if . == null then empty elif (.assignees | length) > 0 then empty else .number end' <<<"$existing")"
    if [ -z "$num" ]; then continue; fi
    if can_assign "$user"; then
      act "assign #$num -> @$user  ($title)" gh issue edit "$num" --repo "$REPO" --add-assignee "$user"
      n=$((n + 1))
    fi
  done 3< <(jq -c '.[]' <<<"$ISSUES")
  log ""
  log "  Issue di-assign: $n (hanya yang belum punya assignee)"
}

# ---------- langkah 4: GitHub Project (v2) ----------
step_project() {
  info "GitHub Project"
  local ptitle; ptitle="$(jq -r '.project.title' <<<"$DATA")"

  if [ "$DRY" = 1 ]; then
    log "  [dry-run] project: \"$ptitle\" (owner: $OWNER) — dibuat bila belum ada, lalu ditautkan ke $REPO"
    log "  [dry-run] field : Poin (NUMBER) · Prioritas (Must/Should/Could) · Gerbang Charter (M3..M9)"
    log "  [dry-run] status: memakai field bawaan Status (Todo/In Progress/Done)"
    jq -r '.[] | "  [dry-run] item  : \(.title)  (poin \(.points // "-") | \(.prio // "-") | \(.gate // "-"))"' <<<"$ISSUES"
    return 0
  fi

  local num pid fields issues_json i title url item points prio gate plist me POWNER="$OWNER"
  if me="$(gh api user --jq .login </dev/null 2>/dev/null)" && [ "$me" = "$OWNER" ]; then POWNER="@me"; fi
  if ! plist="$(gh project list --owner "$POWNER" --limit 100 --format json </dev/null 2>&1)"; then
    die "Gagal mengakses GitHub Project milik '$OWNER': $plist
       Pastikan token adalah PAT classic dengan scope 'project' (bukan fine-grained, bukan GITHUB_TOKEN bawaan Actions)."
  fi
  num="$(jq -r --arg t "$ptitle" '[.projects[] | select(.title == $t)][0].number // empty' <<<"$plist")"
  if [ -z "$num" ]; then
    num="$(gh project create --owner "$POWNER" --title "$ptitle" --format json </dev/null | jq -r '.number')"
    log "  + project #$num: $ptitle"
  else
    log "  = project #$num sudah ada: $ptitle"
  fi
  pid="$(gh project view "$num" --owner "$POWNER" --format json </dev/null | jq -r '.id')"
  gh project link "$num" --owner "$POWNER" --repo "$REPO" </dev/null >/dev/null 2>&1 \
    || warn "Tidak bisa menautkan project ke repo (mungkin sudah tertaut / versi gh lama). Lanjut."

  fields="$(gh project field-list "$num" --owner "$POWNER" --limit 50 --format json </dev/null)"
  has_field() { jq -e --arg n "$1" 'any(.fields[]; .name == $n)' <<<"$fields" >/dev/null; }

  if ! has_field "Poin"; then
    gh project field-create "$num" --owner "$POWNER" --name "Poin" --data-type NUMBER </dev/null >/dev/null
    log "  + field: Poin"
  fi
  if ! has_field "Prioritas"; then
    gh project field-create "$num" --owner "$POWNER" --name "Prioritas" --data-type SINGLE_SELECT \
      --single-select-options "Must,Should,Could" </dev/null >/dev/null
    log "  + field: Prioritas"
  fi
  if ! has_field "Gerbang Charter"; then
    gh project field-create "$num" --owner "$POWNER" --name "Gerbang Charter" --data-type SINGLE_SELECT \
      --single-select-options "M3,M4,M5,M6,M7,M8,M9" </dev/null >/dev/null
    log "  + field: Gerbang Charter"
  fi
  fields="$(gh project field-list "$num" --owner "$POWNER" --limit 50 --format json </dev/null)"
  fid() { jq -r --arg n "$1" '.fields[] | select(.name == $n) | .id' <<<"$fields"; }
  oid() { jq -r --arg n "$1" --arg o "$2" '.fields[] | select(.name == $n) | .options[] | select(.name == $o) | .id' <<<"$fields"; }
  local f_poin f_prio f_gate
  f_poin="$(fid "Poin")"; f_prio="$(fid "Prioritas")"; f_gate="$(fid "Gerbang Charter")"

  issues_json="$(gh issue list --repo "$REPO" --state all --limit 1000 --json title,url </dev/null)"
  local added=0
  while IFS= read -r i <&3; do
    title="$(jq -r '.title' <<<"$i")"
    url="$(jq -r --arg t "$title" '[.[] | select(.title == $t)][0].url // empty' <<<"$issues_json")"
    if [ -z "$url" ]; then warn "Issue tidak ditemukan di repo, dilewati: $title"; continue; fi
    item="$(gh project item-add "$num" --owner "$POWNER" --url "$url" --format json </dev/null | jq -r '.id')"
    points="$(jq -r '.points // empty' <<<"$i")"
    prio="$(jq -r '.prio // empty' <<<"$i")"
    gate="$(jq -r '.gate // empty' <<<"$i")"
    if [ -n "$points" ]; then
      gh project item-edit --id "$item" --project-id "$pid" --field-id "$f_poin" --number "$points" </dev/null >/dev/null
    fi
    if [ -n "$prio" ]; then
      gh project item-edit --id "$item" --project-id "$pid" --field-id "$f_prio" \
        --single-select-option-id "$(oid "Prioritas" "$prio")" </dev/null >/dev/null
    fi
    if [ -n "$gate" ]; then
      gh project item-edit --id "$item" --project-id "$pid" --field-id "$f_gate" \
        --single-select-option-id "$(oid "Gerbang Charter" "$gate")" </dev/null >/dev/null
    fi
    added=$((added + 1))
    log "  + item: $title"
  done 3< <(jq -c '.[]' <<<"$ISSUES")
  log ""
  log "  Item diproses: $added (menambah ulang item yang sudah ada tidak membuat duplikat)"
}

# ---------- jalankan ----------
if want labels;     then step_labels;     fi
if want milestones; then step_milestones; fi
if want issues;     then step_issues;     fi
if want assign;     then step_assign;     fi
if want project;    then step_project;    fi

info "Selesai$( [ "$DRY" = 1 ] && printf ' (DRY-RUN: tidak ada yang diubah)' )"
if [ "$DRY" = 1 ]; then
  log "  Jika rencana sudah sesuai, jalankan tanpa --dry-run."
else
  log "  Langkah manual: buat tampilan (Board/Table/Roadmap) di GitHub Project; belum bisa dibuat lewat gh."
fi

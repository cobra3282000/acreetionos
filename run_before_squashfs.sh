#!/usr/bin/env bash
#
# Pre-squashfs hook. mkarchiso calls this from _run_mksquashfs() immediately
# before mksquashfs packs the airootfs.
#
# mkarchiso in this repository is Arch's file with EndeavourOS's changes
# marked in place, so profile-specific work goes here rather than into it:
# every edit made directly in mkarchiso is one more difference to carry
# through the next merge from upstream, and this hook is the place upstream
# never touches.
#
# Usage: run_before_squashfs.sh [<airootfs-dir> <path-about-to-be-packed>]
#
# The second argument is what mksquashfs is about to read. In the build mode
# this profile uses (airootfs_image_type="squashfs") it is the directory
# itself. In ext4+squashfs mode the image was already built from that
# directory before this hook runs, so nothing done here could reach it - say
# so instead of pretending to have changed something.

set -euo pipefail

root="${1:-}"
packed="${2:-}"

say() { printf 'run_before_squashfs: %s\n' "$*"; }

# Two ways of being called, both real. The copy of mkarchiso in this
# repository passes the directory and the path about to be packed. Older
# copies call the hook with no arguments at all, so fall back to the layout
# mkarchiso uses by default: work/<arch>/airootfs under the directory the
# build was started from.
if [[ -z "${root}" ]]; then
    shopt -s nullglob
    candidates=("${PWD}"/work/*/airootfs)
    shopt -u nullglob
    if ((${#candidates[@]} == 1)); then
        root="${candidates[0]}"
        say "no directory passed by the call site; working on ${root}"
    fi
fi

if [[ -z "${root}" || ! -d "${root}" ]]; then
    # Never fail here. This step only reports sizes and tidies up: if the
    # airootfs really is missing, mksquashfs on the next line fails with a
    # message of its own, and a build that has already spent hours must not
    # be killed by the hook that was added to keep it alive.
    say "no airootfs directory to work on (argument: '${1:-<none>}'); skipping cleanup."
    exit 0
fi

if [[ -n "${packed}" && "${packed}" != "${root}" ]]; then
    say "packing '${packed}', which was built from '${root}' before this hook ran;"
    say "changes to the directory would not reach that image - nothing to do."
    exit 0
fi

# The stock cleanup says nothing about what is being packed. Two numbers are
# the least that make a build tell you something about the image it produced.
size_kib() {
    du -xsk -- "$1" 2>/dev/null | cut -f1 || true
}

mib() {
    awk -v k="$1" 'BEGIN { printf "%.1f MiB", k / 1024 }'
}

before="$(size_kib "${root}")"
before="${before:-0}"
say "airootfs size before: $(mib "${before}")"

# --- removals -------------------------------------------------------------

# Every target is tested first. Most of these only exist when something has
# put them there, and a build must not fail because a file was already gone.

# Files matching a glob inside a directory; prints nothing when nothing
# matches.
drop_in() {
    local dir="$1" pattern="$2" what="$3"
    local -a hits=()
    [[ -d "${dir}" ]] || return 0
    shopt -s nullglob
    # The pattern is meant to expand here - that is the whole point of the
    # argument - and every caller passes a pattern without whitespace, so the
    # unquoted expansion cannot split into anything unexpected.
    # shellcheck disable=SC2206
    hits=("${dir}"/${pattern})
    shopt -u nullglob
    ((${#hits[@]})) || return 0
    rm -rf -- "${hits[@]}"
    say "removed ${what} (${#hits[@]})"
}

drop_file() {
    [[ -e "$1" ]] || return 0
    rm -f -- "$1"
    say "removed $1"
}

# SSH host keys. No package installs them and pacstrap never runs sshd, so the
# image does not carry any today; the guard is here so a future
# `ssh-keygen -A` in customize_airootfs.sh cannot bake one key into every
# system installed from this image. sshdgenkeys.service regenerates them on
# the first start of sshd, so their absence is not a problem.
drop_in "${root}/etc/ssh" 'ssh_host_*' 'SSH host key(s)'

# Same reasoning: systemd writes this when it runs, which it never does during
# a build, and it reseeds on every boot regardless.
drop_file "${root}/var/lib/systemd/random-seed"

# Upstream clears /var/tmp and /var/log but not /tmp and /run, where the chroot
# steps leave things behind. Both are mounted over at boot, so anything left
# here costs image size and nothing else.
drop_in "${root}/tmp" '*' 'entries from /tmp'
drop_in "${root}/run" '*' 'entries from /run'

# Build-time noise in the live session's root home. Only these four: the large
# files under /root are deliberate, and taking them out of the image is a
# separate decision with its own issue.
for noise in .bash_history .wget-hsts .lesshst .viminfo; do
    drop_file "${root}/root/${noise}"
done

# _cleanup_pacstrap_dir() in this repository's mkarchiso writes this file into
# every image, carrying the wrong distribution's name on an AcreetionOS image,
# and nothing in the repository reads it. Removing it here rather than
# deleting the block in mkarchiso keeps the EndeavourOS-marked sections
# untouched, so the next merge from upstream has one less thing to reconcile.
drop_file "${root}/usr/lib/endeavouros-release"

# --- report ---------------------------------------------------------------

# One pass over the tree gives both numbers: du prints a directory's own
# total after its children, so the last line is the size of the whole tree
# and the lines above it are the breakdown printed below.
after_report="$(du -x -d1 -k -- "${root}" 2>/dev/null || true)"
after="$(printf '%s\n' "${after_report}" | tail -n1 | cut -f1)"
after="${after:-0}"
freed=$((before - after))
if ((freed < 0)); then
    freed=0
fi
say "airootfs size after:  $(mib "${after}") (freed $(mib "${freed}"))"

# What is left, biggest first. The default cleanup reports none of this, and
# it is the only way to see what the image is actually made of without
# unpacking it afterwards. The tree total is left out because the size report
# above already gave it, and it is dropped by comparing the path rather than
# the line position because on a small tree a child can tie with the total.
say "largest entries (KiB):"
printf '%s\n' "${after_report}" | sort -rn | while IFS=$'\t' read -r kib path; do
    if [[ -n "${path}" && "${path}" != "${root}" ]]; then
        printf '  %s\t%s\n' "${kib}" "${path}"
    fi
done | head -7 || true

exit 0

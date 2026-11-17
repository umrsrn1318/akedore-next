# AKEDORE Next kernel 4.19 — CHANGELOG

POCO F1 (beryllium / SDM845). Base: **Aozora 4.19** by Kaiyaa77 (Linux
4.19.325, CLO cip135-st19). Everything below is on top of that base.

Version string reports `5.10.245-akedore-umrsrn-v1-KSU` / `-NonKSU` (TEST builds:
`5.10.245-fsociety-umrsrn-v1-*`) (Aozora spoofs the
KERNELVERSION to 5.10.245; the real base is 4.19.325).

Root variant (TEST2.0 and later): **KernelSU 32704** — backslashxx/KernelSU, the
official-compatible driver (`KernelSU` submodule), paired with the **official
KernelSU manager v3.3.1 (32704)**. TEST1.x used KernelSU-Next 33219 + SUSFS
(sections below).

Two builds from one source: **KSU** (`CONFIG_KSU=y`) and **NonKSU** (no root).

---

## AKEDORE Next v1 (20261117)

- **Name**: the kernel is now **AKEDORE Next**. uname reads
  `5.10.245-akedore-next-v1-KSU-SUSFS` (`-KSU`, `-NonKSU`). Same 5.10.245
  spoof as before (see below); the real kernel is 4.19.325.
- **USB PD**: release the wakeup hold taken by `kick_usbpd_vbus_sm()` when
  `usbpd_vbus_sm()` is done (unless `usbpd_sm` owns it). Before, an OTG VBUS
  reset could keep the phone awake. Reported in Abdelrahman-Muhammad a94e7a7e.
- **Fuel gauge**: `voltage_now` returns the last good value when a register
  read fails, instead of an error that healthd reads as 0 mV (possible
  shutdown). Internal FG logic still sees the real result. Idea from
  Abdelrahman-Muhammad de88c67a.
- Checked against duckyduckG 4.19 `perf` (RisingOS-Revived 8.1.1 base) vs
  `lineage-23.2_xiaomi`: the fuel gauge code is the same for beryllium (only
  `#ifdef` moves), so the battery % issue is not from that change.

## 20261108 - 20261109 (v1)

- **Version name**: uname reads `5.10.245-akedore-v1-KSU-SUSFS` (`-v1-KSU`,
  `-v1-NonKSU`). The real kernel is 4.19.325. The `5.10.245` text is Aozora's
  Makefile spoof (`KERNELVERSION = 5.10.245`, commit 1caca3f39a19 by Kaiyaa77),
  kept as it is. Only the version text is changed.
- **Root**: KernelSU 32704 replaced by ReSukiSU v4.2.0-rc3 (35171, UAPI 4).
  The old KernelSU 32704 text in the sections below is history.
- **SUSFS**: ReSukiSU inline hooks for SUSFS v2.3.0 (static keys).
- **TEST-20261108**: Jiro features, plus USB, reboot and QC fixes made for
  the Broken Heart reports.
- `FUSE_BPF` off in the defconfig.
- **NetHunter**: rtl8812au (88XXau) Wi-Fi driver added.
- **Charging**: FCC 3.3 A (Infinity-X parity).
- Status: reboot fix tested on device. Battery jump and USB fixes are
  mitigations, not proven on every phone.

---

## 20261106

- **Battery % like 4.9 (PMI8998 fuel gauge)** — the known 4.19 F1 bug: % stuck
  for a long time then dropping fast, or jumping after a reboot. The SOC code is
  the same as 4.9; four 4.19-only differences were not: MEM_ARB low latency and
  PEEK_MUX4 left on permanently (PM8150B workarounds), atomic SRAM writes not
  synced to SOC_UPDATE when DMA is used, step charging + SW JEITA set up only on a
  profile reload, and a wrong fg pointer in `esr_filter_work`. All four now
  behave like 4.9 on PMI8998. The Xiaomi SOC smoothing also closes a large
  shown-vs-real gap faster (quarter steps above 5 %) and lets the shown % drop
  while charging when it is more than 3 % above the real value.
- **Fast charge while the battery is cool** — thermal-engine picks the charge
  level from xo_therm (~41 °C with the screen on), which held PD/PPS chargers to
  ~5 W. The charge level now follows the battery temperature: full speed below
  42 °C, capped (level 5, ~2 A input) below 45 °C, stock above. Hardware JEITA
  still applies. Knobs: `/sys/module/smb_lib/parameters/fastchg_{cool,warm}`
  (420 / 450, 0 = stock).
- **HyperOS nodes** — `thermal_message/board_sensor_temp` (board temperature for
  PowerKeeper / SecurityCenter, from quiet_therm else xo_therm) and
  `/proc/cpumaxfreq` (About phone CPU clock). On Xiaomi vendors mi_thermald
  writes the first; the F1 ports have no mi_thermald.

## 20261105

- **Two builds: Standard and AutoBoost.** New option
  `CONFIG_FSOCIETY_GPU_AUTOBOOST` sets the boot default of
  `fsociety.gpu_autoboost`. Standard (`n`): the GPU stays at the stock 710 MHz
  ceiling; the boost can still be turned on at runtime (`gpu_autoboost=1`) or the
  game profile picked. AutoBoost (`y`, the TEST2.0 - v1 behaviour): 710 MHz,
  lifted to 802 MHz while a game keeps the GPU pinned. Version string
  `-akedore-umrsrn-v1-KSU` (Standard) / `-akedore-umrsrn-v1-AutoBoost-KSU`.
- Zip names: `AKEDORE-4.19-<KSU|NoSU>-<Standard|AutoBoost>-<date>.zip`.

## v1 (2026-11-04)

- **Renamed: fsociety kernel -> AKEDORE kernel.** Branding only: version string
  (`-akedore-umrsrn-v1-KSU` / `-NonKSU`), build host, installer text and
  `build_akedore.sh`. The code is TEST2.3 unchanged. Internal names stay as
  they were, so existing setups keep working: `/sys/module/fsociety/parameters/*`,
  `CONFIG_FSOCIETY_TUNER`, the fsociety Kernel Control module.
- Older entries below keep the old name (TEST1.x / TEST2.x were released as
  fsociety kernel).

## TEST2.3 (2026-11-01)

- **Standby drain: SoC system sleep works** — the Aozora `sdm845.dtsi` named the
  system-pm node `qcom,system-pm-sdm845`, but `drivers/soc/qcom/system_pm.c` only
  matches `qcom,system-pm` (as Kyzuna 4.19 and every 4.9 tree do). The driver never
  bound, lpm-levels skipped the only RPMh-notify cluster level and the APSS never
  reached system sleep on any 4.19 build of this tree. One-line DT fix. Measured on
  OxygenOS 16 (30 min screen off, Wi-Fi on): ~45 mA vs 55–58 mA on TEST2.2.
- **Camera: `no_i2c` switch for a dead AF actuator** —
  `/sys/module/cam_actuator_core/parameters/no_i2c`, bit N = actuator cell-index N:
  its I2C settings are dropped and reported as applied. A broken autofocus motor
  fails every CCI write after ~0.8 s and made camera preview crawl (2–3 fps) and
  closing slow (~7 s, Settings QR scanner ANR). Off by default; a ROM can enable
  it per device.

## TEST2.2 (2026-11-01)

- **Xiaomi thermal profile really applied** — `thermal_message/sconfig` ignored the
  written value (always 10), and thermal-engine only re-reads it on an inotify
  event that nothing sends outside MIUI, so every 4.19 ROM ran the default profile
  (big cores capped from ~35 °C xo_therm). sconfig now stores the value and is
  re-announced with `sysfs_notify` every 30 s. Measured: +55 % sustained CPU,
  xo_therm held around 51 °C.
- **Charging temperature limit** — thermal-engine writes
  `battery/system_temp_level` (the 4.9 name); qpnp-smb2 only had
  `charge_control_limit`. Both names now map to the same handler.

## TEST2.0 (2026-10-27)

- **fsociety tuner** (`drivers/misc/fsociety_tuner.c`,
  `/sys/module/fsociety/parameters/profile`): eco / balanced / game profiles, GPU
  game boost, screen-off CPU caps, MGLRU kept on.
- **TCP BBR by default** (cubic and westwood kept), fq + fq_codel.
- **USB with PCs that use Power Delivery** — a PD-capable PC port is reported as
  USB (file transfer offered) and remembered across PD hard resets.
- **KernelSU** — switched to backslashxx/KernelSU 32704 (official-compatible),
  source hooks only where the driver does not hook itself.
- **cpuidle** — one lpm hrtimer per CPU.
- **Backports**: MGLRU fixes and reclaim progress (Yu Zhao, Minchan Kim,
  Flicker372), zram fixes (Kairui Song, Sergey Senozhatsky, Longlong Xia, Alexey
  Romanov), UFS pm_qos only on the IRQ CPU (Sultan Alsawaf), qmi_rmnet powersave
  workqueue unbound + freezable (LibXZR), smb-lib clamps charging parameters
  (jiro28), FocalTech no touch reads while suspended (jiro28), IPA panic on data
  path disable timeout (neroices), bpf nospec stack slot fix, futex robust exit
  race, af_alg zero-copy removal.

## TEST1.1 – TEST1.5 (2026-10-20 – 10-25)

- SELinux: deny `PTRACE_TRACEME` like an enforcing device even when permissive.
- usbpd: don't raise Rp to 1.5 A on sink attach (4.9 behaviour).
- Reboot guard and named device shutdown.
- KernelSU: plain manual hooks when SUSFS is off.

## TEST1.0 (2026-10-19)

- **Android 17 bootloop (`bpfloader-failed`)** — backport of upstream
  772412176fb9 *"bpf: Allow rewriting to ports under ip_unprivileged_port_start"*.
  ROMs that set `ro.bpf.kver_override` to 5.15 load netd
  bind programs that return 3; the old verifier only allowed 0–1, netbpfload
  failed and init rebooted. Full feature backported (flags in
  `__inet_bind`/`__inet6_bind`, `BPF_PROG_RUN_ARRAY_FLAGS`, verifier range 0–3).
  Reference backport: Beryllium-Labs / jiro28.
- **Shorter `/proc/version`** — compiler/linker GitHub URLs removed from the
  kernel banner.
- User tests: reboot fix OK over 10–15 reboots; USB replug OK over 10–15
  replugs (USB + MTP immediately). Battery-jump fix not tested yet.

## Bug fixes — the "4.19 weird bugs" + device-found

- **Reboot → warm reset** `b93d78d4d`
  Force a warm reset via PS_HOLD on every reboot (`qcom,force-warm-reboot` on
  the restart node). On stock 4.19 the PMIC hard reset made some F1s power off
  completely with no charging indication until a forced restart. Origin of the
  idea: LineageOS / Bruno Martins (SDM845).

- **Battery never dies with charge left** `4e750bf47`
  `fg_get_prop_capacity()` returned `-EBUSY` while SOC reporting wasn't ready,
  and the Xiaomi smooth-SOC path passed that error up. healthd turns a failed
  capacity read into 0 %, and BatteryService then powers the phone off at 0 %
  while unplugged. Now it reports `BATT_MISS_SOC` (rc 0) like 4.9, and a
  transient SRAM read error can't read as 0 %.

- **Restore real charger/FG/USB wakelocks** `1514cf19e`
  The Aozora base turned every awake-votable callback into
  `pm_wakeup_event(dev, 500)`, so any vote lasting longer than 500 ms (FG
  profile load, SRAM cycle-count / capacity-learning writes, status_change,
  APSD / Type-C handling) lost its wakelock and the system could suspend
  mid-operation. Restored to `pm_stay_awake()` / `__pm_stay_awake()` in
  smb-lib.c, qpnp-fg-gen3.c, battery.c, smb5-lib.c — no other 4.19 beryllium
  tree has the 500 ms clamp. Prime suspect behind the battery oddities and the
  first-USB-plug miss.

- **Cycle-count fully cleared in SRAM** `07c4e7143`
  `clear_cycle_counter()` wrote `sizeof(count)/sizeof(u8 *)` = 2 bytes, so only
  bucket 0 was zeroed in SRAM while the in-memory copy was fully cleared. Write
  the whole 16 bytes. (Fix from Sultan Alsawaf's sdm660 tree.)

- **QC2 charge thermal-mitigation typo** `1af0852a8`
  Level 10 of `qcom,thermal-mitigation-qc2` was 10255000 µA (10.2 A) — a Xiaomi
  source typo — leaving QC2 unthrottled at that step. Fixed to 1025000 µA.

- **Double-tap-to-wake on FocalTech panels** `4da17b08d`
  The FTS driver queued its suspend on `DRM_EVENT_BLANK`, i.e. after the in-cell
  panel had already powered down, so every i2c write NACKed (-107), gesture mode
  was never entered and DT2W didn't work (~250 errors per screen-off). Now it
  suspends synchronously on `DRM_EARLY_EVENT_BLANK` and, with gesture enabled,
  keeps panel reset/regulators up via `dsi_panel_doubleclick_enable()` like the
  nt36xxx driver. **Not guaranteed on replaced / non-original LCDs** — see Known
  limitations.

- **Long vibrations (≥ 1 s) no longer cut short** `bfb1a141c`
  The Xiaomi haptics branch armed the stop timer with
  `ktime_set(40 / MSEC_PER_SEC, (time_ms % MSEC_PER_SEC) * NSEC_PER_MSEC)` — the
  seconds field is always 0, so a 1000 ms vibration stopped at once and 1500 ms
  became 500 ms. Use `time_ms / MSEC_PER_SEC`. The typo is in Xiaomi's source
  and in every beryllium kernel (incl. 4.9).

- **Per-app battery stats** `d6cedaae3`
  `beryllium_defconfig` asked for `UID_SYS_STATS` but disabled its `PROFILING`
  dependency, so `/proc/uid_cputime` and `/proc/uid_io` were missing. Enabled
  `CONFIG_PROFILING`.

## Android 16 / 17 compatibility

- **CAP_CHECKPOINT_RESTORE (cap 40)** `686019085`
  A17's Rust native-app zygote drops the cap bounding set up to cap 40; with
  `CAP_LAST_CAP = CAP_BPF (39)` the `PR_CAPBSET_READ(40)` returns `EINVAL` and
  the zygote aborts (Chrome/Brave force close). Backported the capability plus
  the SELinux `capability2 checkpoint_restore` permission.

- **Namespaces / cgroups** `1d32a4405`
  Enabled PID & IPC namespaces, SysV IPC, POSIX mqueue, and the
  pids/devices/net_prio cgroups.

## Root — KernelSU-Next + SUSFS

- **KernelSU-Next as the root implementation** `64a0878c5`, `15bda387f`, `79003a7b8`
  KernelSU-Next (kyzuna28 legacy-susfs-v2) wired in as the `KernelSU` submodule;
  SUSFS inline hooks adapted to KernelSU-Next; ReSukiSU hook names mapped to
  KernelSU-Next bools, fstat hook handling adjusted, ReSukiSU selinux-hide
  plumbing compiled out. Thermal zones kept (beryllium-p0.dtsi from Kyzuna,
  which Aozora disables).
- **seccomp filter_count** `b9dc3b283` — added, required by KernelSU-Next.
- **Legacy GET_INFO reply fix** `075563672` — copy the reply to userspace so
  NeoZygisk detects KernelSU.
- **init.rc fstat size hook** `a03e684de` — restored so ksud runs at cold boot
  on A16/A17 (init reads init.rc only up to `st_size`).
- **.gitmodules / build script** `e1783ed61`, `bad1df4e9` — KernelSU submodule
  pin, portable `build_fsociety.sh`, README.

## Profiles & control

- **Standard / OC device-tree profiles** `09679f219`, `85869b8d8`
  Standard = all thermal zones on, GPU capped at the stock 710 MHz; OC = GPU up
  to 802 MHz and the 14 soft zones off (SoC critical trips + LMH stay in both).
  In the shipped builds the Gaming profile is applied at runtime by the
  **fsociety Kernel Control** module instead of a separate OC zip.

## Build / toolchain

- **ThinLTO bootloop fix** `fd32a244b`
  Dropped `-mllvm -always-rename-promoted-locals=false`; with newer clang's
  ThinLTO it left same-named promoted statics unrenamed, so one static shadowed
  another and the kernel panicked at boot.
- **Version string**
  `LOCALVERSION` = `-fsociety-umrsrn-v1-KSU` / `-NonKSU` so the KSU and non-KSU
  builds are distinguishable in Settings → About phone.
- **Type-C status logging** `1094257fc`
  Log the 5 Type-C status bytes on every CC change, to diagnose the rare
  first-USB-plug-after-boot miss.

## Known limitations

- **Double-tap-to-wake** is reliable only with **Always-On Display on**. The
  in-kernel fix arms gesture mode before the panel powers off, but on a replaced
  / **non-original LCD** the touch IC can drop the i2c link once the screen is
  fully off, so a tap isn't always read — **can't be guaranteed**. Keep AOD on
  (gesture mode stays powered) or use lift-to-wake.
- **First USB plug after a cold boot** can rarely miss; re-plug works (Type-C
  status is now logged for diagnosis).

---

## Full commit list

```
1094257fc  smb-lib: log the Type-C status bytes on every CC change
bfb1a141c  leds: qpnp-haptics: fix the Xiaomi stop timer for plays >= 1 s
07c4e7143  power: qpnp-fg-gen3: clear every cycle-count bucket in SRAM
1514cf19e  power: qcom: restore real awake votes (drop 500 ms wakelock timeouts)
d6cedaae3  defconfig: enable PROFILING so UID_SYS_STATS builds
1af0852a8  arm64: dts: beryllium: fix qc2 thermal mitigation typo
4e750bf47  power: qpnp-fg-gen3: never fail capacity reads
4da17b08d  touchscreen: focaltech_mi: suspend on early blank, keep panel up for DT2W
85869b8d8  build_fsociety.sh/README: PROFILE=std|oc
09679f219  fsociety: standard / OC profiles
a03e684de  fs/stat: restore the init.rc fstat hook for KernelSU-Next
075563672  KernelSU: fix legacy GET_INFO reply (NeoZygisk root detection)
686019085  capabilities: add CAP_CHECKPOINT_RESTORE (40)
1d32a4405  defconfig: enable PID/IPC namespaces, SysV IPC, POSIX mqueue, cgroups
bad1df4e9  fsociety: README
e1783ed61  fsociety: KernelSU submodule (.gitmodules), build_fsociety.sh
b9dc3b283  seccomp: add filter_count (needed by KernelSU-Next)
fd32a244b  Makefile: drop -always-rename-promoted-locals=false (ThinLTO bootloop)
b93d78d4d  fsociety: force warm reboot (PS_HOLD) - fixes reboot -> power off
79003a7b8  fsociety: map ReSukiSU hooks to KernelSU-Next
64a0878c5  fsociety: KernelSU-Next (kyzuna28 legacy-susfs-v2) as KernelSU
15bda387f  fsociety: adapt SUSFS inline hooks to KernelSU-Next; keep thermal zones
---------  (base: Aozora 4.19 by Kaiyaa77)
```

## Base (inherited from Aozora 4.19 v1.0 — credit @Kaiyaa77Ar)

MGLRU (`LRU_GEN`) · NtSync · WALT scheduler · Maple I/O scheduler (default) ·
zram + LZ4 · Boeffla WL blocker · SUSFS 2.2.0 · KernelSU-Next · Neutron Clang 24
(ThinLTO + CFI). These ship in the Aozora v1.0 base, not fsociety's own work.

## Credits

@Kaiyaa77Ar (Kaiyaa77) — Aozora 4.19 base · @kyzuna28 (Kyy) — Kyzuna 4.19 dtsi &
KernelSU-Next legacy fork · KernelSU-Next team (rifsxd, tiann, Mr-Morat) ·
simonpunk — SUSFS · diphons — SDM845 4.19 port · LineageOS / Bruno Martins —
force-warm-reboot idea · Sultan Alsawaf — cycle-count clear fix ·
Stanislav Fomichev — upstream BPF bind patch · Beryllium-Labs / jiro28 — 4.19
backport reference · the Linux kernel & CodeLinaro / Qualcomm sources · the
POCO F1 / SDM845 community.

Licensed under GPL-2.0.

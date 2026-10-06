# Strategi Branch — Sistem Informasi Terintegrasi UKM Lembaga Pers ITERA

Proyek IF25-40312 Proyek Teknologi Informasi · Kelompok JNT · Periode 7 Sep – 29 Nov 2026

Dokumen ini menjadi aturan kerja Git bersama untuk 4 anggota tim. Tujuannya sederhana: kode `main` selalu bisa jalan, setiap perubahan bisa dilacak ke satu issue, dan tidak ada yang saling menimpa pekerjaan.

---

## 1. Ringkasan (baca ini dulu)

| Hal | Aturan |
|---|---|
| Branch permanen | Hanya satu: `main` |
| Branch kerja | Pendek (1–3 hari), dibuat dari `main`, dihapus setelah merge |
| Cara membuat branch | Dari tombol **Development → Create a branch** di issue, atau `gh issue develop` |
| Cara memasukkan kode | Pull Request ke `main`, minimal 1 approval, **Squash and merge** |
| Menutup issue | Tulis `Closes #nomor` di deskripsi PR, issue tertutup otomatis saat merge |
| Deploy | `main` → Production di Vercel. Setiap PR → URL Preview otomatis |
| Push langsung ke `main` | **Dilarang** (dikunci lewat branch protection) |

Alasan tidak memakai branch `develop`: tim hanya 4 orang dan Vercel sudah memberi preview untuk setiap PR, sehingga `develop` hanya menambah satu langkah merge tanpa manfaat tambahan.

---

## 2. Peran dan kepemilikan

Diambil dari Project Charter dan penugasan di GitHub Project.

| Anggota | Peran | Username GitHub | Fokus branch |
|---|---|---|---|
| Choirunnisa Syawaldina | Project Manager | `@choirunnisasy` | `docs/`, `chore/` (dokumen, Project board) |
| Garis Rayya Rabbani | Back-End Developer | `@GarsRayy` | irisan **Live** (API, database, DOKU) |
| Refi Ikhsanti | Front-End Developer | `@7refisa` | irisan **UI** (halaman, komponen) |
| Keira Lakeisha Fachra Fuady | Quality Assurance | `@keiralakeisha` | `fix/` hasil pengujian, reviewer utama |

Aturan review:
- Penulis PR **tidak boleh** menyetujui PR-nya sendiri.
- Kode ditinjau oleh anggota lain, dengan Keira sebagai reviewer utama untuk pengujian.
- PR dokumen (`docs/`) ditinjau Choirunnisa atau Garis.

---

## 3. Struktur branch

```
main  ──●────●────●────●────●────●──►  (selalu stabil, deploy Production)
         \  /      \  /      \  /
          ●         ●         ●          (branch kerja pendek)
   feat/F-03-ui-…  feat/F-03-live-…  fix/F-04-live-…
```

Hanya ada `main` dan branch kerja. Tidak ada `develop`, `release/`, atau `staging` permanen.

---

## 4. Penamaan branch

Format:

```
<jenis>/<ID-backlog>-<irisan>-<deskripsi-singkat>
```

| Jenis | Dipakai untuk | Contoh |
|---|---|---|
| `feat/` | fitur baru (irisan UI atau Live) | `feat/F-03-ui-editor-berita` |
| `fix/` | perbaikan bug, terutama saat Internal Testing | `fix/F-04-live-status-artikel` |
| `docs/` | dokumen, revisi SKPL, README | `docs/P-08-revisi-skpl` |
| `chore/` | setup, konfigurasi, dependency, CI | `chore/P-14-init-nextjs` |
| `hotfix/` | perbaikan mendesak setelah deployment | `hotfix/D-02-link-share-rusak` |

Aturan:
- Huruf kecil, kata dipisah tanda hubung, tanpa spasi.
- ID backlog ditulis apa adanya (`F-03`, `P-08`, `T-02`). Kalau ID punya huruf (`F-01a`), pertahankan: `feat/F-01a-ui-login`.
- Irisan ditulis `ui` atau `live` agar jelas pekerjaan siapa.
- Satu branch = satu issue.

### Membuat branch dari issue

**Lewat web:** buka issue → sidebar kanan **Development** → **Create a branch**. GitHub mengusulkan nama otomatis (misalnya `12-judul-issue`). Ganti dengan format di atas sebelum menekan Create.

**Lewat terminal:**

```bash
git checkout main && git pull
gh issue develop 12 --name "feat/F-03-ui-editor-berita" --checkout
```

Cara ini otomatis menautkan branch ke issue #12.

---

## 5. Alur kerja satu issue

1. **Ambil issue.** Pilih issue yang ditugaskan kepadamu, pastikan status di Project berubah ke *In Progress*.
2. **Sinkronkan `main`.** `git checkout main && git pull`.
3. **Buat branch** dari `main` (lihat bagian 4).
4. **Kerjakan dengan commit kecil.** Satu commit = satu perubahan logis (lihat bagian 6).
5. **Sinkronkan secara berkala.** Minimal sekali sehari: `git fetch origin && git rebase origin/main` (atau `git merge origin/main` kalau belum nyaman dengan rebase).
6. **Push dan buka PR** ke `main`. Isi template PR (bagian 7), tulis `Closes #nomor`.
7. **Cek URL Preview Vercel** yang muncul di PR, pastikan tampilan dan fiturnya benar.
8. **Review.** Perbaiki komentar reviewer. Reviewer mencentang acceptance criteria di issue.
9. **Squash and merge.** Judul commit gabungan mengikuti format commit (bagian 6).
10. **Selesai.** Issue tertutup otomatis, branch terhapus otomatis, status Project jadi Done.

---

## 6. Konvensi commit

Format (Conventional Commits, bahasa Indonesia boleh):

```
<jenis>(<cakupan>): <ringkasan singkat> (#nomor-issue)
```

| Jenis | Arti |
|---|---|
| `feat` | fitur baru |
| `fix` | perbaikan bug |
| `docs` | dokumen |
| `style` | format/tampilan tanpa ubah logika |
| `refactor` | merapikan kode tanpa ubah perilaku |
| `test` | tambah/ubah pengujian |
| `chore` | konfigurasi, dependency, build |

Contoh:

```
feat(cms): tambah autosave draf tiap 30 detik (#12)
fix(editorial): artikel Rejected tidak bisa diajukan ulang (#31)
feat(pembayaran): terima webhook DOKU dan perbarui status pesanan (#44)
docs(skpl): samakan target Lighthouse dengan Project Charter (#8)
chore: inisialisasi proyek Next.js (#5)
```

Cakupan yang disarankan: `auth`, `profil`, `cms`, `editorial`, `berita`, `katalog`, `pesanan`, `pembayaran`, `dashboard`, `storage`, `ui`.

Aturan:
- Ringkasan maksimal sekitar 72 karakter, kata kerja di depan, tanpa titik di akhir.
- Judul PR memakai format yang sama, karena itu yang menjadi pesan commit saat squash.
- Jangan commit file rahasia (`.env`, kunci API, kredensial DOKU).

---

## 7. Pull Request

### Aturan PR
- Ukuran kecil: idealnya di bawah 400 baris berubah. PR besar dipecah.
- Satu PR = satu issue.
- Jangan merge PR dengan status check gagal atau konflik yang belum selesai.
- PR yang masih dikerjakan dibuka sebagai **Draft**.

### Template PR

Simpan sebagai `.github/pull_request_template.md`:

```markdown
## Ringkasan
<!-- Apa yang diubah dan kenapa, 1-3 kalimat -->

Closes #

## Jenis perubahan
- [ ] feat (UI)
- [ ] feat (Live)
- [ ] fix
- [ ] docs / chore

## Acceptance criteria
<!-- Salin dari issue, centang yang sudah terpenuhi -->
- [ ]
- [ ]

## Cara menguji
1.
2.

## Checklist
- [ ] Sudah diuji di URL Preview Vercel
- [ ] Tampilan dicek di lebar 360px dan 1024px
- [ ] Tidak ada rahasia/kunci API yang ikut ter-commit
- [ ] Dokumentasi/komentar diperbarui bila perlu
- [ ] Branch sudah disinkronkan dengan `main` terbaru

## Tangkapan layar (jika ada perubahan tampilan)
```

### Kepemilikan kode

Simpan sebagai `.github/CODEOWNERS` agar reviewer terpilih otomatis:

```
# Default: semua perubahan butuh review QA
*                       @keiralakeisha

# Dokumen
/docs/                  @choirunnisasy
*.md                    @choirunnisasy

# Backend / API / pembayaran
/app/api/               @GarsRayy
/lib/                   @GarsRayy
/supabase/              @GarsRayy

# Frontend
/components/            @7refisa
/app/(public)/          @7refisa
/app/(admin)/           @7refisa
```

Sesuaikan jalur folder dengan struktur proyek Next.js yang sebenarnya.

---

## 8. Pasangan irisan UI dan Live

Setiap fitur di backlog dipecah menjadi irisan **UI** (Milestone M3, memakai data dummy) dan **Live** (Milestone M4–M6, tersambung backend). Aturannya:

1. **Satu branch per irisan**, bukan satu per fitur.
2. Irisan UI di-merge ke `main` lebih dulu, lengkap dengan data dummy.
3. Irisan Live dibuat dari `main` setelah UI ter-merge, lalu mengganti data dummy dengan API.
4. Refi dan Garis hampir tidak menyentuh file yang sama, sehingga konflik merge jarang.
5. Kalau Garis butuh bentuk data sebelum UI selesai, sepakati dulu kontrak API (nama field, tipe) di issue, lalu kerjakan paralel.

---

## 9. Hubungan dengan milestone Charter

| Gerbang | Periode | Isi utama | Aturan branch |
|---|---|---|---|
| M1 | 7 Sep – 4 Okt | Perencanaan | `docs/`, `chore/` |
| M2 | 5 – 11 Okt | Analisis & desain | `docs/`, desain, skema database |
| M3 | 12 – 18 Okt | Front End (dummy) | `feat/…-ui-…` |
| M4 | 12 Okt – 1 Nov | Backend & integrasi | `feat/…-live-…` |
| M5 | 26 Okt – 8 Nov | Fitur produk + DOKU | `feat/…-live-…` |
| M6 | 26 Okt – 8 Nov | Dashboard & pendukung | `feat/` |
| M7 | 9 – 15 Nov | Internal testing | **hanya `fix/`**, tidak ada fitur baru |
| M8 | 16 – 22 Nov | UAT bersama mitra | **code freeze**, hanya `fix/` untuk bug UAT |
| M9 | 23 – 29 Nov | Deployment & handover | `hotfix/`, `docs/` |

### Penandaan rilis (tag)

Setelah semua issue dalam satu gerbang tertutup dan milestone GitHub di-close, beri tag di `main`:

```bash
git checkout main && git pull
git tag -a m3-frontend -m "M3: Front End selesai (data dummy)"
git push origin m3-frontend
```

Daftar tag: `m1-perencanaan`, `m2-desain`, `m3-frontend`, `m4-backend`, `m5-produk`, `m6-dashboard`, `m7-testing`, `m8-uat`, `v1.0.0` (rilis final M9).

Tag memberi titik kembali yang jelas bila ada masalah dan menjadi bukti dokumentasi tiap gerbang.

---

## 10. Pengaturan repository

### Branch protection untuk `main`

Settings → Branches → Add branch ruleset / protection rule:

- [x] Require a pull request before merging
  - [x] Require approvals: **1**
  - [x] Dismiss stale approvals when new commits are pushed
  - [x] Require review from Code Owners
- [x] Require status checks to pass before merging (centang `lint`/`build` setelah CI dibuat, serta check Vercel)
- [x] Require branches to be up to date before merging
- [x] Require conversation resolution before merging
- [x] Block force pushes
- [x] Restrict deletions

### Pengaturan merge

Settings → General → Pull Requests:

- [x] Allow squash merging (judul default: *Pull request title*)
- [ ] Allow merge commits
- [ ] Allow rebase merging
- [x] Automatically delete head branches

### Otomatisasi Project

Project → ⋯ → Workflows, aktifkan:
- *Item closed* → Status **Done**
- *Pull request merged* → Status **Done**
- *Auto-add to project* untuk issue baru

Nama dan pilihan menu bisa sedikit berbeda, cek langsung di menunya.

### CI minimal (opsional, disarankan)

Simpan sebagai `.github/workflows/ci.yml`:

```yaml
name: CI
on:
  pull_request:
    branches: [main]
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm
      - run: npm ci
      - run: npm run lint --if-present
      - run: npm run build
```

Dengan ini PR yang gagal build tidak bisa di-merge.

---

## 11. Vercel, Supabase, dan DOKU

### Vercel
- `main` → **Production**. Setiap PR → **Preview** dengan URL unik.
- Variabel lingkungan dibuat per lingkungan (Production / Preview / Development). Jangan pernah menulis kunci di kode.
- Gunakan URL Preview untuk review dan demo ke mitra sebelum merge.

### Supabase
- Idealnya pisahkan project **dev/staging** dan **production**, supaya preview PR tidak menulis ke data produksi. Paket gratis biasanya mengizinkan lebih dari satu project, cek kuota akunmu.
- Perubahan skema database disimpan sebagai file migrasi di repo (misalnya `supabase/migrations/`) dan masuk lewat PR, bukan diubah manual di dashboard saja.
- Perubahan skema yang mengubah tabel inti (`pengguna`, `artikel`, `pesanan`) wajib disebut di deskripsi PR dan ditinjau Garis dan Keira.

### DOKU (pembayaran)
- Selama pengembangan pakai **mode sandbox** dan saldo uji. Kunci sandbox dan produksi disimpan terpisah.
- Webhook DOKU butuh URL publik. URL Preview Vercel berubah tiap PR, jadi pengujian webhook lebih mudah di satu lingkungan tetap (misalnya deployment `main` yang memakai kunci sandbox), atau memakai tunnel seperti ngrok saat berkembang lokal.
- Status pesanan lunas hanya boleh diubah dari webhook yang tervalidasi, bukan dari halaman sukses di browser.
- Pindah ke kunci produksi dilakukan hanya di M9, lewat PR khusus `chore/D-xx-kunci-doku-produksi`.

### Rahasia
- `.env*` masuk `.gitignore`. Simpan contoh variabel di `.env.example` tanpa nilai asli.
- Kalau kunci terlanjur ter-commit: anggap bocor, **ganti kuncinya** di layanan terkait, jangan hanya menghapus commit.
- Aktifkan *Secret scanning* di Settings → Code security bila tersedia.

---

## 12. Menangani konflik dan situasi khusus

**Konflik merge saat PR.**
1. `git fetch origin`
2. `git rebase origin/main` (atau `git merge origin/main`)
3. Selesaikan konflik di file yang ditandai, jalankan ulang aplikasi, `git add` lalu `git rebase --continue`.
4. `git push --force-with-lease` (hanya ke branch milikmu sendiri, tidak pernah ke `main`).

**Dua orang butuh mengubah file yang sama.** Bicarakan dulu di issue. Biasanya yang satu merge lebih dulu, yang lain sinkronkan lalu lanjut.

**Branch berumur lebih dari 3 hari.** Pecah issue menjadi bagian lebih kecil atau merge bagian yang sudah stabil lebih dulu (fitur disembunyikan dengan flag bila belum selesai).

**Salah commit ke `main` secara lokal.**
```bash
git branch feat/F-03-ui-editor-berita   # simpan pekerjaan ke branch baru
git reset --hard origin/main            # kembalikan main lokal
```

**Perubahan ternyata merusak `main`.** Buat PR `git revert <commit>` sebagai jalan tercepat, lalu perbaiki di branch terpisah.

**Hotfix setelah deployment (M9).**
1. Buat `hotfix/D-xx-deskripsi` dari `main`.
2. PR dengan label `hotfix`, review cepat oleh 1 orang.
3. Merge, pastikan deploy Production sukses, beri tag patch (`v1.0.1`).

---

## 13. Definition of Done

Issue boleh ditutup hanya bila:

- [ ] Semua acceptance criteria di issue tercentang.
- [ ] Kode sudah di-review dan di-merge ke `main` lewat PR.
- [ ] Sudah diuji di URL Preview atau Production, termasuk lebar 360px dan 1024px bila ada tampilan.
- [ ] Tidak ada error di console dan build berhasil.
- [ ] Untuk irisan Live: alur utamanya sudah diuji dengan data nyata, tidak lagi memakai data dummy.
- [ ] Dokumentasi terkait (README, catatan handover, SKPL bila perlu) sudah diperbarui.

---

## 14. Perintah Git cepat

```bash
# mulai pekerjaan
git checkout main && git pull
gh issue develop <nomor> --name "feat/F-03-ui-editor-berita" --checkout

# simpan pekerjaan
git add -p
git commit -m "feat(cms): tambah toolbar editor (#12)"
git push -u origin HEAD

# sinkronkan dengan main
git fetch origin
git rebase origin/main
git push --force-with-lease

# buka PR dari terminal
gh pr create --fill --base main

# lihat status
git status -sb
gh pr status

# bersihkan branch lokal yang sudah merge
git checkout main && git pull
git branch --merged | grep -v "main" | xargs -r git branch -d
```

---

## 15. Hal yang dilarang

- Push langsung ke `main`.
- `git push --force` ke `main` atau branch orang lain.
- Merge PR sendiri tanpa review.
- Commit `.env`, kunci DOKU, atau kata sandi.
- Satu PR berisi banyak issue tak berhubungan.
- Menambah fitur baru pada fase M7 dan M8 (hanya `fix/`).

---

## 16. Daftar pemasangan awal (dikerjakan sekali oleh PM/Garis)

- [ ] Buat `.github/pull_request_template.md`
- [ ] Buat `.github/CODEOWNERS`
- [ ] Buat `.github/workflows/ci.yml`
- [ ] Aktifkan branch protection untuk `main`
- [ ] Atur merge: hanya Squash, hapus branch otomatis
- [ ] Aktifkan workflow otomatis di GitHub Project
- [ ] Hubungkan repo ke Vercel, atur variabel lingkungan per lingkungan
- [ ] Buat `.env.example` dan pastikan `.env*` ada di `.gitignore`
- [ ] Bagikan dokumen ini ke seluruh anggota dan sepakati di rapat internal

---

*Versi 1.0 · disusun 4 Oktober 2026 · perbarui dokumen ini bila ada keputusan tim yang mengubah aturan.*

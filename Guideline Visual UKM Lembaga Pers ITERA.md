# Guide Sistem Desain (Light Theme) - WebLempers

Dokumen ini merangkum sistem desain dengan pendekatan tema yang terang, segar, dan ringan (Light Theme) menggunakan warna utama *Sky Blue / Ocean*. Panduan ini mencakup palet warna, tipografi, dan komponen UI berdasarkan konfigurasi Tailwind dan CSS global.

---

## 1. Tipografi

Proyek ini menggunakan paduan tipografi modern dan bersih (optimasi via Google Fonts).

- **Display Font (`--font-display`)**: **Space Grotesk**
  - Karakteristik: Geometris, modern, tegas.
  - Digunakan untuk: Judul utama (`h1`, `h2`, `h3`, `h4`), angka metrik, dan elemen dengan class `.font-display`.
- **Body Font (`--font-body`)**: **Plus Jakarta Sans**
  - Karakteristik: Jernih, tingkat keterbacaan tinggi untuk UI.
  - Digunakan untuk: Teks utama/body secara keseluruhan, paragraf, dan label.

---

## 2. Palet Warna (Light & Fresh)

Desain ini menggantikan warna *Navy* gelap dengan palet biru cerah/langit (Sky Blue) sebagai warna **Primary**, yang memberikan kesan aplikasi lebih bersih, transparan, dan terbuka.

### Warna Utama Tailwind (`primary`)
| Bobot | Kode Hex | Visualisasi / Fungsi Utama |
|:---:|:---:|---|
| **50** | `#f0f9ff` | Biru sangat terang (Background lapis terbawah) |
| **100** | `#e0f2fe` | Biru pucat (Background komponen / hover soft) |
| **200** | `#bae6fd` | Biru muda pucat |
| **300** | `#7dd3fc` | Biru langit muda |
| **400** | `#38bdf8` | Biru terang |
| **500** | `#0ea5e9` | **Biru Primer (Sky) - CTA & Aksen Utama** |
| **600** | `#0284c7` | Biru medium-gelap (Hover pada tombol primer) |
| **700** | `#0369a1` | Biru laut (Garis tepi tebal / teks penekanan) |
| **800** | `#075985` | Biru laut gelap |
| **900** | `#0c4a6e` | Biru pekat |
| **950** | `#082f49` | Biru sangat gelap pekat |

### Variabel Dasar CSS (Tema Terang)
Digunakan pada `:root` dalam `globals.css`:
- **Background**: Kombinasi bersih mulai dari `#f8fafc` ke `#e0f2fe`.
- **Foreground**: `#111827` (Slate 900) untuk teks agar kontras tetap tajam.
- **Card**: `rgba(255, 255, 255, 0.9)` (Transparansi putih untuk kesan *Glassmorphism*).
- **Border**: `rgba(17, 24, 39, 0.1)` (Batas elemen yang sangat halus).
- **Ink**: `#0f172a` (Slate 950 untuk teks judul berat).
- **Signal**: `#d97706` (Amber 600 - Aksen notifikasi, alert, atau status "Proses").
- **Signal Soft**: `#fef3c7` (Amber 100 - Background lembut untuk status notifikasi).

---

## 3. Latar Belakang & Tekstur (Backgrounds)

Latar belakang halaman mengedepankan kesan ruang lapang dan modern:

- **Gradiasi Lembut**:
  Latar utama menggunakan gradasi linear dan pendaran cahaya (*glow*) radial halus dari warna Sky Blue dan Amber.
  ```css
  background:
    radial-gradient(circle at top left, rgba(14, 165, 233, 0.15), transparent 34%),
    radial-gradient(circle at 95% 10%, rgba(217, 119, 6, 0.16), transparent 30%),
    linear-gradient(180deg, #f8fafc 0%, #e0f2fe 100%);
  ```
- **`.bg-noise`**: Mengaplikasikan overlay tekstur *noise* halus berbasis SVG. Tujuannya untuk memberikan kedalaman (depth) sehingga background gradasi tidak terlihat *flat*.

---

## 4. Efek dan Bayangan (Shadows)

Bayangan digunakan untuk mengangkat elemen-elemen dari background terang.

- **`.glass-panel`**: Komponen utama pembentuk layout (kartu, form). Menggunakan warna `var(--card)` transparan dipadukan efek bluring background `-webkit-backdrop-filter: blur(18px)`.
- **Shadow `soft`**: `0 20px 60px -24px rgba(11, 27, 58, 0.38)` - Bayangan lebar yang menyebar, bagus untuk modal atau menu *dropdown*.
- **Shadow `card`**: `0 12px 32px -18px rgba(15, 23, 42, 0.35)` - Bayangan tajam ke bawah untuk kartu konten.

---

## 5. Komponen & Pola UI Spesifik

- **`.section-title`**: Judul bagian kecil (uppercase, spasi huruf renggang, bold). Warna teks diatur menggunakan `#0284c7` (Sky-600) untuk paduan yang menyegarkan.
- **`.editorial-shell`**: Pembungkus layout dengan efek grid titik-titik transparan `radial-gradient(rgba(15, 23, 42, 0.05) 0.5px, transparent 0.5px)` yang memberikan struktur rapi di atas latar terang.
- **Berita/Ticker**:
  - **`.headline-ticker` & `.headline-track`**: Pembungkus teks bergerak untuk pengumuman atau headline berita yang berjalan melintasi layar.
  - **`.headline-pill`**: Lencana (badge) kapsul dengan latar putih semi-transparan `rgba(255,255,255,0.82)`.
  - **`.headline-dot`**: Titik warna peringatan (`#d97706`) sebagai pemisah.

---

## 6. Animasi (Motion Design)

Pengalaman UI diperhalus dengan deretan animasi CSS siap pakai:

- **`.reveal-fade`**: Efek muncul ke atas yang elegan saat *scrolling* atau muat awal.
- **`.animate-fade-in-up`**: Varian lain dari reveal (durasi lambat: 0.6s).
- **`ticker-scroll`**: Pergerakan terus-menerus (`linear infinite`) untuk teks berjalan.
- **`splash-fade`**: Hilangnya layar pemuatan (*Splash Screen*).
- **`typewriter`**: Efek mengetik dinamis.
- **`dash-pulse`**: Efek kelap-kelip batas luar elemen (biasanya memakai warna *Signal*).
- **`.skeleton`**: Efek detak (*pulse*) abu-abu terang (`#e2e8f0`) sebagai keadaan memuat sebelum konten siap.

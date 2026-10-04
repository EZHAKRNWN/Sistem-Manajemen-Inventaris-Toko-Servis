import 'package:flutter/material.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isGenerating = false;

  final List<Map<String, String>> _messages = [
    {
      'role': 'assistant',
      'text':
          'Halo, Bos! 👋 Saya asisten diagnostik SmartFix kamu. '
          'Tanya aja soal kerusakan HP, prosedur servis, pinout IC, '
          'atau estimasi stok sparepart — saya bantu sebisa mungkin! 😊',
    },
  ];

  final List<String> _quickPrompts = [
    'iPhone 13 boot loop, kenapa ya?',
    'Cara aman lepas baterai bengkak',
    'Pinout IC charging Samsung S22',
    'HP kena air, langkah pertama apa?',
    'Layar OLED bergaris, penyebabnya?',
    'Tips solder IC kecil tanpa hot air',
  ];

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSendPrompt(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;

    _promptController.clear();
    setState(() {
      _messages.add({'role': 'user', 'text': query});
      _isGenerating = true;
    });

    _scrollToBottom();

    // Simulasi delay respons AI
    await Future.delayed(const Duration(milliseconds: 1200));

    final aiReply = _generateSimulatedResponse(query);

    if (mounted) {
      setState(() {
        _messages.add({'role': 'assistant', 'text': aiReply});
        _isGenerating = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Simulated AI response engine (Bahasa Indonesia) ─────────────────────
  String _generateSimulatedResponse(String prompt) {
    final q = prompt.toLowerCase();

    // Boot loop
    if (q.contains('boot loop') || q.contains('bootloop') || q.contains('restart terus')) {
      return 'Oke, soal boot loop nih ya — cukup sering kejadian. '
          'Coba langkah-langkah ini:\n\n'
          '1️⃣ Cek tegangan VDD_MAIN di terminal baterai (~3.8V–4.2V). '
          'Kalau drop di bawah 3.5V, kemungkinan baterai udah lemah.\n'
          '2️⃣ Lepas flex sensor proximity dan earpiece, lalu coba nyalakan lagi. '
          'Kadang korosi di konektor flex bikin short.\n'
          '3️⃣ Kalau logo Apple/Samsung muncul terus mati, coba masuk DFU mode '
          'dan cek error code pakai 3uTools atau Odin.\n'
          '4️⃣ Terakhir, periksa NAND — kalau IC penyimpanan rusak, '
          'biasanya butuh reball atau ganti.\n\n'
          'Semoga membantu, Bos! Kabarin hasilnya ya 💪';
    }

    // Baterai bengkak / swollen
    if (q.contains('baterai') || q.contains('battery') || q.contains('bengkak') || q.contains('swollen')) {
      return 'Nah, soal baterai bengkak ini harus hati-hati banget ya, Bos! ⚠️\n\n'
          '1️⃣ Jangan sekali-kali tusuk atau tekan baterai yang bengkak — '
          'bisa kebakaran atau meledak.\n'
          '2️⃣ Lepas konektor flex baterai dulu sebelum nyentuh komponen lain.\n'
          '3️⃣ Pakai IPA (isopropyl alcohol) 99% untuk melunakkan lem perekat di bawah baterai.\n'
          '4️⃣ Congkel pelan-pelan pakai spudger plastik, jangan pakai alat logam!\n'
          '5️⃣ Simpan baterai bekas di wadah tahan api (LiPo safe bag).\n\n'
          'Kalau baterainya udah kembung parah, mending langsung ganti baru aja. '
          'Safety first! 🔥🧯';
    }

    // Charging / pengisian daya
    if (q.contains('charging') || q.contains('cas') || q.contains('ngecas') || q.contains('charger') || q.contains('pengisian')) {
      return 'Masalah charging emang tricky, Bos. Nih saya kasih langkah diagnosis:\n\n'
          '1️⃣ Cek port USB/Lightning — seringkali cuma kotoran debu yang numpuk di dalamnya. '
          'Bersihin pakai sikat anti-statis.\n'
          '2️⃣ Test pakai kabel & charger lain. Kadang masalahnya bukan di HP-nya.\n'
          '3️⃣ Ukur tegangan di pin konektor charging pakai multimeter. '
          'Harusnya ada 5V masuk.\n'
          '4️⃣ Kalau tegangan masuk tapi baterai nggak ngisi, '
          'kemungkinan IC charging (PMIC) rusak dan perlu direball atau diganti.\n'
          '5️⃣ Untuk Samsung S-series, IC charging biasanya SM5714 atau MAX77705.\n\n'
          'Cek juga apakah HP bisa cas wireless — kalau bisa, berarti port-nya yang bermasalah 👍';
    }

    // Layar / LCD / OLED
    if (q.contains('layar') || q.contains('lcd') || q.contains('oled') || q.contains('screen') || q.contains('display') || q.contains('bergaris')) {
      return 'Soal masalah layar ya, Bos? Ini beberapa kemungkinan:\n\n'
          '1️⃣ Layar bergaris / ada garis hijau → biasanya IC driver layar (DDIC) rusak, '
          'terutama kalau HP pernah jatuh. Solusinya ganti layar.\n'
          '2️⃣ Layar blank tapi HP hidup (ada suara/getar) → cek konektor flex display '
          'di motherboard, mungkin kendor atau pin-nya patah.\n'
          '3️⃣ Sentuhan nggak responsif → coba cek flex digitizer, '
          'atau mungkin ada ghost touch karena lem frame yang longgar.\n'
          '4️⃣ Kalau ganti layar OLED, pastikan pakai yang original atau OEM grade — '
          'yang TFT murah biasanya warnanya pudar dan refresh rate beda.\n\n'
          'Untuk penggantian, panaskan frame pakai heat gun di 80°C biar lem lama lunak 👌';
    }

    // Kamera
    if (q.contains('kamera') || q.contains('camera') || q.contains('foto')) {
      return 'Problem kamera ya? Coba dicek begini, Bos:\n\n'
          '1️⃣ Kalau kamera blank / hitam → pastikan konektor flex kamera '
          'terpasang rapat di motherboard.\n'
          '2️⃣ Kalau goyang atau nggak fokus → kemungkinan OIS (Optical Image Stabilizer) rusak. '
          'Biasanya ada suara "klik-klik" kalau dikocok.\n'
          '3️⃣ Error "Kamera Gagal" setelah update → coba clear cache app kamera, '
          'atau factory reset kalau perlu.\n'
          '4️⃣ Untuk iPhone, kalau ganti kamera belakang non-original, '
          'fitur True Tone & auto-focus bisa terdisable karena pairing chip.\n\n'
          'Selalu test kamera sebelum tutup casing ya! 📸';
    }

    // Speaker / audio
    if (q.contains('speaker') || q.contains('audio') || q.contains('suara') || q.contains('mic') || q.contains('microphone')) {
      return 'Masalah audio / speaker nih? Sering banget:\n\n'
          '1️⃣ Speaker bawah nggak bunyi → cek dulu pakai mode loudspeaker saat telepon. '
          'Kalau earpiece normal tapi speaker bawah mati, kemungkinan flex speaker putus.\n'
          '2️⃣ Suara kecil / pecah → mungkin mesh speaker tersumbat kotoran. '
          'Bersihin pakai sikat halus + IPA.\n'
          '3️⃣ Mic nggak berfungsi saat telepon → cek mic primer (biasanya di bawah) '
          'dan mic noise-cancelling (biasanya di atas). Test pakai voice recorder.\n'
          '4️⃣ Kalau setelah ganti LCD suara hilang, cek apakah karet gasket speaker '
          'masih terpasang — tanpa gasket, suara bocor keluar.\n\n'
          'Jangan lupa test semua mic & speaker sebelum serah ke customer ya! 🔊';
    }

    // Sinyal / jaringan
    if (q.contains('sinyal') || q.contains('signal') || q.contains('jaringan') || q.contains('network') || q.contains('sim')) {
      return 'HP hilang sinyal atau nggak baca SIM? Ini bisa beberapa penyebab:\n\n'
          '1️⃣ Cek slot SIM — mungkin pin konektor bengkok atau ada korosi.\n'
          '2️⃣ Pastikan SIM card masih aktif dan nggak expired. Test di HP lain.\n'
          '3️⃣ Kalau sinyal hilang total, kemungkinan IC baseband/modem bermasalah. '
          'Ini repair level advance (reball/ganti IC).\n'
          '4️⃣ Untuk iPhone, cek apakah IMEI masih terbaca di Settings → About. '
          'Kalau IMEI hilang / unknown, IC baseband pasti rusak.\n'
          '5️⃣ Coba reset network settings dulu sebelum bongkar hardware.\n\n'
          'Semoga cuma masalah software ya, Bos! 📶';
    }

    // Water damage / kena air
    if (q.contains('air') || q.contains('water') || q.contains('basah') || q.contains('rendam') || q.contains('kena air')) {
      return 'Waduh, HP kena air ya Bos? Ini urutan penanganan yang benar:\n\n'
          '1️⃣ JANGAN NYALAKAN HP! Ini paling penting. Langsung matikan kalau masih hidup.\n'
          '2️⃣ Buka casing & lepas baterai (kalau bisa dilepas) secepat mungkin.\n'
          '3️⃣ Rendam motherboard di IPA 99% selama 5-10 menit untuk mendisplace air '
          'dan mencegah korosi.\n'
          '4️⃣ Sikat semua konektor & area IC pakai sikat anti-statis di bawah mikroskop.\n'
          '5️⃣ Keringkan pakai udara hangat (bukan hot air langsung!) atau silica gel selama 24 jam.\n'
          '6️⃣ Setelah bersih & kering, cek setiap fungsi satu-satu sebelum dirakit.\n\n'
          'Ingat ya, JANGAN pakai beras! Itu mitos dan malah bisa bikin debu masuk. 🚫🍚';
    }

    // IC / chip
    if (q.contains('ic ') || q.contains('chip') || q.contains('pinout') || q.contains('pmic') || q.contains('nand')) {
      return 'Oke Bos, soal IC/chip ini ya. Beberapa tips:\n\n'
          '1️⃣ Sebelum angkat IC, pastikan suhu hot air station sudah dikalibrasi. '
          'Untuk IC kecil: 320-350°C, untuk BGA besar: 380-420°C.\n'
          '2️⃣ Pakai flux berkualitas (Amtech/UV-11) biar timah reballing merata.\n'
          '3️⃣ Untuk cek pinout, bisa referensi ke ZXW Tool atau skematik board.\n'
          '4️⃣ IC PMIC yang sering bermasalah:\n'
          '   • iPhone: 338S00456 (PMIC utama)\n'
          '   • Samsung: S2MU106, MAX77705\n'
          '   • Xiaomi: Qualcomm PMI8998\n'
          '5️⃣ Kalau IC NAND rusak, data biasanya nggak bisa diselamatkan. '
          'Kasih tahu customer dari awal.\n\n'
          'Hati-hati ya Bos, satu IC kecil bisa senilai ratusan ribu! 💎';
    }

    // Solder
    if (q.contains('solder') || q.contains('reball') || q.contains('reflow') || q.contains('timah')) {
      return 'Tips soldering dari saya nih, Bos:\n\n'
          '1️⃣ Untuk SMD komponen kecil (kapasitor, resistor), pakai solder tip '
          'ukuran BC1 atau BC2 dengan suhu 330-350°C.\n'
          '2️⃣ Selalu pakai flux! Tanpa flux, timah nggak akan nempel sempurna '
          'dan bisa bikin cold solder joint.\n'
          '3️⃣ Teknik reball IC: bersihkan pad lama → pasang stencil → '
          'isi bola timah → reflow pakai hot air.\n'
          '4️⃣ Jangan lupa preheater di bawah PCB kalau kerja sama BGA — '
          'tanpa preheat, board bisa melengkung (warping).\n'
          '5️⃣ Praktik di board bekas dulu sebelum kerjain board customer! 🎯\n\n'
          'Kalau butuh referensi video, banyak tutorial bagus di YouTube '
          'dari channel Jessa Jones (iPad Rehab). Recommended! 👍';
    }

    // Inventaris / stok
    if (q.contains('inventaris') || q.contains('inventory') || q.contains('stok') || q.contains('stock') || q.contains('sparepart')) {
      return 'Soal manajemen inventaris & sparepart ya, Bos? Ini saran saya:\n\n'
          '1️⃣ Selalu catat setiap sparepart yang masuk & keluar di sistem. '
          'Pakai fitur SmartFix supaya nggak kelewatan.\n'
          '2️⃣ Untuk part yang fast-moving (LCD iPhone, baterai Samsung), '
          'sedia minimal 3-5 unit buffer stock.\n'
          '3️⃣ Part impor dari China biasanya lead time 7-14 hari kerja. '
          'Order lebih awal biar nggak kehabisan.\n'
          '4️⃣ Simpan IC dan chip sensitif di anti-static bag + silica gel.\n'
          '5️⃣ Pisahkan part original, OEM, dan aftermarket — '
          'jangan sampai tertukar waktu servis!\n\n'
          'Toko yang rapi = pelanggan percaya = bisnis lancar! 📦✨';
    }

    // Flex cable
    if (q.contains('flex') || q.contains('kabel') || q.contains('konektor')) {
      return 'Masalah flex cable itu sensitif banget, Bos:\n\n'
          '1️⃣ Jangan pernah tarik flex cable secara paksa — bisa putus jalur di dalamnya.\n'
          '2️⃣ Pakai spudger plastik untuk membuka kunci konektor FPC sebelum melepas flex.\n'
          '3️⃣ Kalau pin konektor di motherboard bengkok, luruskan pelan-pelan pakai pinset '
          'di bawah mikroskop.\n'
          '4️⃣ Flex charging port, flex power/volume, dan flex home button '
          'paling sering rusak karena keausan.\n'
          '5️⃣ Selalu test fungsi setelah pasang flex baru — jangan langsung tutup casing.\n\n'
          'Satu tips: beli flex OEM dari supplier terpercaya. '
          'Yang abal-abal biasanya cuma tahan 1-2 minggu 😅';
    }

    // Screw / baut
    if (q.contains('screw') || q.contains('baut') || q.contains('sekrup') || q.contains('torque') || q.contains('pentalobe')) {
      return 'Soal baut & sekrup HP ya, Bos? Jangan dianggap remeh! 🔩\n\n'
          '1️⃣ iPhone pakai pentalobe (bintang 5 titik) untuk baut luar, '
          'dan tri-point (Y000) untuk baut dalam. Siapkan obeng khusus.\n'
          '2️⃣ Samsung kebanyakan pakai Phillips #000.\n'
          '3️⃣ JANGAN over-torque! Baut HP itu kecil banget — '
          'kalau dipaksa bisa stripped (dol) dan susah dilepas nanti.\n'
          '4️⃣ Simpan baut di magnetic mat atau screw organizer. '
          'Baut HP itu super kecil, gampang ilang!\n'
          '5️⃣ Catat posisi setiap baut — ukurannya bisa beda-beda walau tampak mirip. '
          'Pasal baut yang salah bisa nembus motherboard! ⚠️\n\n'
          'Pro tip: foto posisi baut sebelum buka casing 📸';
    }

    // Software / reset
    if (q.contains('software') || q.contains('reset') || q.contains('flash') || q.contains('firmware') || q.contains('update') || q.contains('hang')) {
      return 'Masalah software ya, Bos? Ini beberapa langkah standar:\n\n'
          '1️⃣ HP lemot / hang → coba clear cache partition dulu (bukan factory reset).\n'
          '2️⃣ Stuck di logo → masuk recovery mode, coba wipe cache. '
          'Kalau tetap, flash ulang firmware.\n'
          '3️⃣ Untuk flash Samsung: pakai Odin + firmware dari SamFW.\n'
          '   Untuk Xiaomi: pakai Mi Flash Tool + ROM dari official site.\n'
          '   Untuk iPhone: pakai iTunes/3uTools.\n'
          '4️⃣ SELALU backup data customer dulu sebelum flash! 📱\n'
          '5️⃣ Kalau setelah flash tetap bermasalah, '
          'kemungkinan hardware (eMMC/NAND) yang rusak.\n\n'
          'Ingat, flash firmware bisa void warranty kalau nggak hati-hati. '
          'Kasih disclaimer ke customer ya! 📝';
    }

    // Fallback — jawaban umum dalam Bahasa Indonesia
    return 'Oke Bos, saya coba analisis pertanyaan "$prompt" ya:\n\n'
        '🔍 Langkah awal yang saya sarankan:\n'
        '1️⃣ Periksa secara visual di bawah mikroskop 40x — '
        'cari retakan solder atau komponen SMD yang bergeser.\n'
        '2️⃣ Cek ketersediaan sparepart terkait di inventaris SmartFix.\n'
        '3️⃣ Estimasi waktu pengerjaan: sekitar 45-60 menit untuk diagnosis awal.\n\n'
        'Kalau bisa, kirim foto kerusakan atau jelaskan gejalanya lebih detail — '
        'biar saya bisa kasih saran yang lebih spesifik. '
        'Saya di sini siap bantu kapan aja! 💪😊';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Diagnostik Servis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Chat',
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add({
                  'role': 'assistant',
                  'text': 'Chat direset! 🔄 Ada yang bisa saya bantu hari ini, Bos?',
                });
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Prompts
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: _quickPrompts.map((prompt) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      label: Text(prompt, style: const TextStyle(fontSize: 12)),
                      avatar: const Icon(Icons.auto_awesome, size: 14),
                      onPressed: () => _handleSendPrompt(prompt),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Message Bubbles
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.82,
                    ),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
                        bottomLeft: !isUser ? const Radius.circular(0) : const Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isUser ? Icons.person : Icons.smart_toy_outlined,
                              size: 14,
                              color: isUser ? Colors.white70 : theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isUser ? 'Teknisi' : 'SmartFix AI',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isUser ? Colors.white70 : theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          msg['text'] ?? '',
                          style: TextStyle(
                            color: isUser ? Colors.white : theme.colorScheme.onSurface,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          if (_isGenerating)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'SmartFix AI sedang menganalisis skematik...',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

          // Prompt Input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (val) => _handleSendPrompt(val),
                    decoration: InputDecoration(
                      hintText: 'Tanya soal servis HP atau diagnostik...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.send_rounded),
                  onPressed: () => _handleSendPrompt(_promptController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

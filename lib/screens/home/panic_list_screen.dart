import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:reang_app/models/panic_kontak_model.dart';
import 'package:url_launcher/url_launcher.dart';

class PanicListScreen extends StatefulWidget {
  final List<PanicKontakModel> contacts;
  final String title;

  const PanicListScreen({
    super.key,
    required this.contacts,
    required this.title,
  });

  @override
  State<PanicListScreen> createState() => _PanicListScreenState();
}

class _PanicListScreenState extends State<PanicListScreen> {
  bool _isCalling = false;

  // Fungsi untuk melakukan panggilan
  Future<void> _makePhoneCall(String phoneNumber) async {
    // Mencegah panggilan ganda jika tombol ditekan berkali-kali
    if (_isCalling) return;
    setState(() => _isCalling = true);

    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Tidak dapat melakukan panggilan ke $phoneNumber';
      }
    } catch (e) {
      if (mounted) {
        showToast(
          e.toString(),
          context: context,
          backgroundColor: Colors.red,
          position: StyledToastPosition.bottom,
          animation: StyledToastAnimation.scale,
          reverseAnimation: StyledToastAnimation.fade,
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      // Beri jeda sesaat sebelum mengizinkan panggilan lagi
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() => _isCalling = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.contacts.length,
        itemBuilder: (context, index) {
          final contact = widget.contacts[index];

          // Menggunakan widget kartu kustom yang baru
          return _PanicListItem(
            contact: contact,
            theme: theme,
            onTap: () => _makePhoneCall(contact.nomer),
          );
        },
      ),
    );
  }
}

/// Widget Kustom Baru untuk Tampilan Daftar yang Lebih Bagus
class _PanicListItem extends StatelessWidget {
  final PanicKontakModel contact;
  final ThemeData theme;
  final VoidCallback onTap;

  const _PanicListItem({
    required this.contact,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // Gunakan InkWell agar seluruh kartu memiliki efek ripple saat disentuh
      child: InkWell(
        onTap: onTap, // <-- SELURUH KARTU BISA DITEKAN
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            children: [
              // --- IKON MERAH ---
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.red.withOpacity(
                  0.1,
                ), // Latar belakang ikon
                child: Icon(
                  contact.icon,
                  color: Colors.red.shade700, // <-- Ikon berwarna merah
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // --- Teks Nama dan Nomor ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contact.nomer,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // --- Ikon Petunjuk Aksi ---
              Icon(
                Icons.call_outlined,
                color: theme.hintColor.withOpacity(0.5),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

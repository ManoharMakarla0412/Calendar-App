import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class CollapsibleAdBanner extends StatefulWidget {
  const CollapsibleAdBanner({super.key});

  @override
  State<CollapsibleAdBanner> createState() => _CollapsibleAdBannerState();
}

class _CollapsibleAdBannerState extends State<CollapsibleAdBanner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isCollapsed = true;

  // Test IDs for development
  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-3940256099942544/2934735716';

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('BannerAd failed to load: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isCollapsed = !_isCollapsed),
          child: Container(
            height: _isCollapsed ? 24 : 50,
            width: double.infinity,
            color: Colors.grey.withValues(alpha: 0.1),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isCollapsed)
                  const Text('ADVERTISEMENT', style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
                if (!_isCollapsed)
                  AdWidget(ad: _bannerAd!),
                Positioned(
                  right: 8,
                  child: Icon(
                    _isCollapsed ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class PosScannerDialog extends StatefulWidget {
  const PosScannerDialog({super.key});

  @override
  State<PosScannerDialog> createState() => _PosScannerDialogState();
}

class _PosScannerDialogState extends State<PosScannerDialog> {
  final MobileScannerController _controller = MobileScannerController(
    autoStart: true,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.green.shade700, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final code = barcodes.first.rawValue;
                  if (code != null) {
                    Navigator.pop(context, code);
                  }
                }
              },
              errorBuilder: (context, error) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'خطأ في الكاميرا: ${error.errorCode}',
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'تأكد من إذن الوصول للكاميرا في ويندوز',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
            // Floating Overlays
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                style: IconButton.styleFrom(backgroundColor: Colors.black45),
              ),
            ),
            Positioned(
              top: 20,
              left: 20,
              child: IconButton(
                onPressed: () => _controller.toggleTorch(),
                icon: ValueListenableBuilder(
                  valueListenable: _controller,
                  builder: (context, state, child) {
                    final status = state.torchState;
                    return Icon(
                      status == TorchState.on ? Icons.flash_on : Icons.flash_off,
                      color: Colors.white,
                    );
                  },
                ),
                style: IconButton.styleFrom(backgroundColor: Colors.black45),
              ),
            ),
            // Targeting UI
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green.shade400, width: 2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  children: [
                    _ScannerCorner(isTop: true, isLeft: true),
                    _ScannerCorner(isTop: true, isLeft: false),
                    _ScannerCorner(isTop: false, isLeft: true),
                    _ScannerCorner(isTop: false, isLeft: false),
                  ],
                ),
              ),
            ),
            const Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'ضع الكود داخل المربع للمسح',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerCorner extends StatelessWidget {
  final bool isTop, isLeft;
  const _ScannerCorner({required this.isTop, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: isTop ? -2 : null,
      bottom: !isTop ? -2 : null,
      left: isLeft ? -2 : null,
      right: !isLeft ? -2 : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: isTop ? BorderSide(color: Colors.green.shade300, width: 6) : BorderSide.none,
            bottom: !isTop ? BorderSide(color: Colors.green.shade300, width: 6) : BorderSide.none,
            left: isLeft ? BorderSide(color: Colors.green.shade300, width: 6) : BorderSide.none,
            right: !isLeft ? BorderSide(color: Colors.green.shade300, width: 6) : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isTop && isLeft ? 12 : 0),
            topRight: Radius.circular(isTop && !isLeft ? 12 : 0),
            bottomLeft: Radius.circular(!isTop && isLeft ? 12 : 0),
            bottomRight: Radius.circular(!isTop && !isLeft ? 12 : 0),
          ),
        ),
      ),
    );
  }
}

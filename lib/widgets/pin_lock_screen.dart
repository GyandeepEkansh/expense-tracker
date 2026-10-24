import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class PinLockScreen extends StatefulWidget {
  final VoidCallback? onUnlocked;
  final bool isSetupMode;
  final Function(String pin)? onPinCreated;

  const PinLockScreen({
    super.key,
    this.onUnlocked,
    this.isSetupMode = false,
    this.onPinCreated,
  });

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _pin = '';
  String? _firstPin;
  String _errorMessage = '';
  bool _isConfirming = false;

  void _onKeyPressed(String val) {
    if (_pin.length < 4) {
      setState(() {
        _pin += val;
        _errorMessage = '';
      });

      if (_pin.length == 4) {
        _handlePinComplete();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = '';
      });
    }
  }

  void _handlePinComplete() {
    if (widget.isSetupMode) {
      if (!_isConfirming) {
        setState(() {
          _firstPin = _pin;
          _pin = '';
          _isConfirming = true;
        });
      } else {
        if (_pin == _firstPin) {
          widget.onPinCreated?.call(_pin);
        } else {
          setState(() {
            _errorMessage = 'PINs do not match. Try again.';
            _pin = '';
            _firstPin = null;
            _isConfirming = false;
          });
        }
      }
    } else {
      final settings = context.read<SettingsProvider>();
      final ok = settings.verifyPin(_pin);
      if (ok) {
        widget.onUnlocked?.call();
      } else {
        setState(() {
          _errorMessage = 'Incorrect PIN';
          _pin = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header
              Column(
                children: [
                  const SizedBox(height: 40),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      size: 36,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.isSetupMode
                        ? (_isConfirming ? 'Confirm your 4-digit PIN' : 'Set a 4-digit PIN')
                        : 'Expense Tracker Locked',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isSetupMode
                        ? 'Keep your personal financial records secure'
                        : 'Enter your PIN to access your expenses',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // PIN Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isFilled = index < _pin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled
                              ? primaryColor
                              : (isDark ? Colors.grey[800] : Colors.grey[300]),
                          border: Border.all(
                            color: isFilled
                                ? primaryColor
                                : (isDark ? Colors.grey[700]! : Colors.grey[400]!),
                            width: 1.5,
                          ),
                        ),
                      );
                    }),
                  ),

                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),

              // Keypad
              Column(
                children: [
                  for (var row = 0; row < 3; row++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (var col = 1; col <= 3; col++)
                            _buildKeyButton('${row * 3 + col}', isDark, primaryColor),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Biometrics / placeholder button
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: !widget.isSetupMode
                              ? IconButton(
                                  icon: Icon(
                                    Icons.fingerprint_rounded,
                                    size: 32,
                                    color: primaryColor,
                                  ),
                                  onPressed: () {
                                    // Quick unlock simulation for biometric
                                    context.read<SettingsProvider>().unlockSession();
                                    widget.onUnlocked?.call();
                                  },
                                )
                              : const SizedBox.shrink(),
                        ),
                        _buildKeyButton('0', isDark, primaryColor),
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: IconButton(
                            icon: Icon(
                              Icons.backspace_outlined,
                              size: 26,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                            onPressed: _onBackspace,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyButton(String text, bool isDark, Color primaryColor) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _onKeyPressed(text),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

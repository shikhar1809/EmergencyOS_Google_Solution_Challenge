import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/copilot_prefs.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';

/// SOS lock, Lifeline voice, and dispatch-bridge preferences (separate from language / general UI).
class EmergencySettingsScreen extends ConsumerStatefulWidget {
  const EmergencySettingsScreen({super.key});

  @override
  ConsumerState<EmergencySettingsScreen> createState() =>
      _EmergencySettingsScreenState();
}

class _EmergencySettingsScreenState extends ConsumerState<EmergencySettingsScreen> {
  bool _hasSosPin = false;
  bool _isSaving = false;
  bool _emergencyBridgeDesk = false;
  bool _voiceCopilotEnabled = true;
  bool _voiceCopilotMuted = false;
  bool _voiceWalkthroughEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadSosPinStatus(),
      _loadCopilotPrefs(),
      _loadBridgeDesk(),
    ]);
  }

  Future<void> _loadSosPinStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      if (doc.exists && doc.data() != null) {
        setState(() {
          _hasSosPin =
              ((doc.data()!['sosPinHash'] as String?)?.trim().isNotEmpty ??
                  false);
        });
      }
    } catch (_) {}
  }

  Future<void> _loadBridgeDesk() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;
      if (doc.exists && doc.data() != null) {
        setState(() {
          _emergencyBridgeDesk =
              (doc.data()!['emergencyBridgeDesk'] as bool?) ?? false;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadCopilotPrefs() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _voiceCopilotEnabled =
          p.getBool(CopilotPrefs.voiceCopilotEnabled) ?? true;
      _voiceCopilotMuted = p.getBool(CopilotPrefs.voiceCopilotMuted) ?? false;
      _voiceWalkthroughEnabled =
          p.getBool(CopilotPrefs.voiceWalkthroughEnabled) ?? false;
    });
  }

  String _pinHash(String uid, String pin) {
    final bytes = utf8.encode('$uid:${pin.trim()}');
    return sha256.convert(bytes).toString();
  }

  Future<void> _setOrChangeSosPin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final result = await showDialog<Map<String, String>?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final l = AppLocalizations.of(dialogContext);
        final pinCtrl = TextEditingController();
        final confirmCtrl = TextEditingController();
        String? error;
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text(
                _hasSosPin ? l.pinChangeTitle : l.pinSetTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: pinCtrl,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: l.pinHintNew,
                      hintStyle: const TextStyle(color: Colors.white38),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirmCtrl,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: l.pinHintConfirm,
                      hintStyle: const TextStyle(color: Colors.white38),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      error!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: Text(
                    l.cancel,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDanger,
                  ),
                  onPressed: () {
                    final pin = pinCtrl.text.trim();
                    final confirm = confirmCtrl.text.trim();
                    if (pin.length < 4) {
                      setLocal(() => error = l.pinErrorTooShort);
                      return;
                    }
                    if (pin != confirm) {
                      setLocal(() => error = l.pinErrorMismatch);
                      return;
                    }
                    Navigator.of(context).pop({'pin': pin});
                  },
                  child: Text(l.save),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;
    final pin = result['pin'] ?? '';
    if (pin.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final hash = _pinHash(user.uid, pin);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sos_pin_hash', hash);

      final connectivity = await Connectivity().checkConnectivity();
      final offline = connectivity.every((r) => r == ConnectivityResult.none);

      if (!offline) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'sosPinHash': hash,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (!mounted) return;
      setState(() => _hasSosPin = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).profilePinSaved),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.profilePinSaveError('$e')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveCopilotBool(String key, bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(key, value);
  }

  Future<void> _saveBridgeDesk() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isSaving = true);
    try {
      final connectivity = await Connectivity().checkConnectivity();
      final offline = connectivity.every((r) => r == ConnectivityResult.none);
      if (!offline) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'emergencyBridgeDesk': _emergencyBridgeDesk,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).profileSavedMsg),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Emergency settings'),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _buildSosPinCard(l),
          const SizedBox(height: 16),
          _buildVoiceSettingsCard(l),
          const SizedBox(height: 16),
          _buildDispatchSettingsCard(l),
        ],
      ),
    );
  }

  Widget _buildSosPinCard(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_rounded, color: AppColors.primaryDanger, size: 20),
              const SizedBox(width: 10),
              Text(
                l.profileSosPinTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _hasSosPin ? Icons.lock_rounded : Icons.lock_open_rounded,
                        color: _hasSosPin ? Colors.greenAccent : Colors.white54,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _hasSosPin ? l.profilePinStatusSet : l.profilePinStatusUnset,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _isSaving ? null : _setOrChangeSosPin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDanger,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  _hasSosPin ? l.profileChangePinBtn : l.profileSetPinBtn,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l.profilePinExitNote,
            style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceSettingsCard(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mic_rounded, color: AppColors.primaryDanger, size: 20),
              const SizedBox(width: 10),
              Text(
                'Lifeline voice',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.profileVoiceAgentEnableTitle, style: const TextStyle(color: Colors.white, fontSize: 14)),
            subtitle: Text(
              l.profileVoiceAgentEnableSubtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            value: _voiceCopilotEnabled,
            activeColor: AppColors.primaryDanger,
            onChanged: (v) => setState(() {
              _voiceCopilotEnabled = v;
              _saveCopilotBool(CopilotPrefs.voiceCopilotEnabled, v);
            }),
          ),
          const Divider(height: 1, color: Colors.white10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.profileVoiceStartMutedTitle, style: const TextStyle(color: Colors.white, fontSize: 14)),
            subtitle: Text(
              l.profileVoiceStartMutedSubtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            value: _voiceCopilotMuted,
            activeColor: AppColors.primaryDanger,
            onChanged: (v) => setState(() {
              _voiceCopilotMuted = v;
              _saveCopilotBool(CopilotPrefs.voiceCopilotMuted, v);
            }),
          ),
          const Divider(height: 1, color: Colors.white10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.profileVoiceWalkthroughTitle, style: const TextStyle(color: Colors.white, fontSize: 14)),
            subtitle: Text(
              l.profileVoiceWalkthroughSubtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            value: _voiceWalkthroughEnabled,
            activeColor: AppColors.primaryDanger,
            onChanged: (v) => setState(() {
              _voiceWalkthroughEnabled = v;
              _saveCopilotBool(CopilotPrefs.voiceWalkthroughEnabled, v);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchSettingsCard(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.outbond_rounded, color: AppColors.primaryDanger, size: 20),
              const SizedBox(width: 10),
              Text(
                'Dispatch bridge',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.profileDispatchDeskTitle, style: const TextStyle(color: Colors.white, fontSize: 14)),
            subtitle: Text(
              l.profileDispatchDeskSubtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            value: _emergencyBridgeDesk,
            activeColor: AppColors.primaryDanger,
            onChanged: (v) => setState(() => _emergencyBridgeDesk = v),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSaving ? null : _saveBridgeDesk,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primaryDanger),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l.save, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

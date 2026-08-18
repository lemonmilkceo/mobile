import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../services/invite_code_hold.dart';
import '../services/session.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  var _mode = _AuthMode.login;
  var _busy = false;
  String? _error;

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _invite = TextEditingController();
  final _phone = TextEditingController();
  var _referrer = 'bae';
  final _referrerName = TextEditingController();
  final _referrerPhone = TextEditingController();

  @override
  void initState() {
    super.initState();
    final code = InviteCodeHold.code;
    if (code != null && code.isNotEmpty) {
      _invite.text = code;
      _mode = _AuthMode.signup;
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _invite.dispose();
    _phone.dispose();
    _referrerName.dispose();
    _referrerPhone.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = '이메일을 입력해 주세요.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AppSession>().client.auth.resetPasswordForEmail(
            email,
            redirectTo: '${AppConfig.apiBase}/reset-password',
          );
      if (mounted) {
        setState(() => _error = '해당 이메일이 가입되어 있으면 재설정 안내를 보냅니다.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = '해당 이메일이 가입되어 있으면 재설정 안내를 보냅니다.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final session = context.read<AppSession>();
    try {
      if (_mode == _AuthMode.login) {
        await session.signIn(_email.text.trim(), _password.text);
      } else {
        await session.api.post('/api/mobile/signup', {
          'inviteCode': _invite.text.trim(),
          'email': _email.text.trim(),
          'password': _password.text,
          'phone': _phone.text.trim(),
          'referrerChoice': _referrer,
          if (_referrer == 'custom') ...{
            'referrerName': _referrerName.text.trim(),
            'referrerPhone': _referrerPhone.text.trim(),
          },
        });
        await session.signIn(
          _email.text.trim(),
          _password.text,
          requireProfileSetup: true,
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
          children: [
            Text(
              'Bae & Lee',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _mode == _AuthMode.login ? '로그인' : '초대 코드로 가입',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 32),
            Form(
              key: _form,
              child: Column(
                children: [
                  if (_mode == _AuthMode.signup) ...[
                    TextFormField(
                      controller: _invite,
                      decoration: const InputDecoration(labelText: '초대 코드'),
                      validator: (v) =>
                          (v == null || v.trim().length < 6) ? '필수' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: '휴대폰',
                        helperText: '앱 알림 수신용',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().length < 10) ? '필수' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _referrer,
                      decoration: const InputDecoration(labelText: '추천인'),
                      items: const [
                        DropdownMenuItem(
                          value: 'bae',
                          child: Text('배지헌 대표'),
                        ),
                        DropdownMenuItem(
                          value: 'lee',
                          child: Text('이현승 대표'),
                        ),
                        DropdownMenuItem(
                          value: 'custom',
                          child: Text('직접 입력'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _referrer = v ?? 'bae'),
                    ),
                    if (_referrer == 'custom') ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _referrerName,
                        decoration:
                            const InputDecoration(labelText: '추천인 본명'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? '필수' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _referrerPhone,
                        keyboardType: TextInputType.phone,
                        decoration:
                            const InputDecoration(labelText: '추천인 연락처'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? '필수' : null,
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: '이메일'),
                    validator: (v) =>
                        (v == null || !v.contains('@')) ? '이메일 확인' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: '비밀번호',
                      helperText:
                          _mode == _AuthMode.signup ? '8자 이상' : null,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return '비밀번호를 입력해 주세요';
                      if (_mode == _AuthMode.signup && v.length < 8) {
                        return '8자 이상';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: Text(_busy
                  ? (_mode == _AuthMode.login ? '로그인 중…' : '가입 중…')
                  : (_mode == _AuthMode.login ? '로그인' : '회원가입')),
            ),
            if (_mode == _AuthMode.login)
              TextButton(
                onPressed: _busy ? null : _sendReset,
                child: const Text('비밀번호를 잊으셨나요?'),
              ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                        _mode = _mode == _AuthMode.login
                            ? _AuthMode.signup
                            : _AuthMode.login;
                        _error = null;
                      }),
              child: Text(
                _mode == _AuthMode.login
                    ? '처음이신가요? 초대 코드로 가입'
                    : '이미 회원이신가요? 로그인',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _AuthMode { login, signup }

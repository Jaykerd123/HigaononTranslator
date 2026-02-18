import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';

class AudioSpectrum extends StatefulWidget {
  final RecorderController recorderController;

  const AudioSpectrum({super.key, required this.recorderController});

  @override
  State<AudioSpectrum> createState() => _AudioSpectrumState();
}

class _AudioSpectrumState extends State<AudioSpectrum> {
  @override
  Widget build(BuildContext context) {
    return AudioWaveform(
      height: 50,
      width: MediaQuery.of(context).size.width * 0.8,
      recorderController: widget.recorderController,
      waveStyle: WaveStyle(
        waveColor: Colors.red,
        showDurationLabel: false,
        spacing: 8.0,
        showBottom: false,
        extendWaveform: true,
        showMiddleLine: false,
      ),
    );
  }
}

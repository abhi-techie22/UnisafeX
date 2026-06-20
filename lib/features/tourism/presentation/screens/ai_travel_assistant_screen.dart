import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unisafex/core/router/app_router.dart';
import 'package:unisafex/core/theme/app_theme.dart';
import 'package:unisafex/features/tourism/domain/entities/tourism_place.dart';
import 'package:unisafex/features/tourism/domain/services/travel_assistant_service.dart';
import 'package:unisafex/features/tourism/presentation/providers/tourism_provider.dart';

class AiTravelAssistantScreen extends ConsumerStatefulWidget {
  const AiTravelAssistantScreen({super.key});

  @override
  ConsumerState<AiTravelAssistantScreen> createState() =>
      _AiTravelAssistantScreenState();
}

class _AiTravelAssistantScreenState
    extends ConsumerState<AiTravelAssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _assistant = const TravelAssistantService();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text: 'Namaste! I’m your UniSafeX travel assistant. Ask me about safe '
          'places, entry fees, timings, seasons, scams, transport, hotels, '
          'food safety, emergencies or a 1–5 day India itinerary.',
      isUser: false,
    ),
  ];

  static const _prompts = [
    'Plan 2 budget days in Delhi',
    'Safest places for solo women in Jaipur',
    'Show hidden gems in Agra',
    'Best historical places in Delhi',
    'Summarize Taj Mahal details',
    'How do I avoid taxi scams?',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send(String value, List<TourismPlace> places) {
    final question = value.trim();
    if (question.isEmpty) return;
    final reply = _assistant.answer(question, places);
    setState(() {
      _messages.add(_ChatMessage(text: question, isUser: true));
      _messages.add(
        _ChatMessage(
          text: reply.text,
          isUser: false,
          places: reply.places,
        ),
      );
      _controller.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final placesState = ref.watch(plannerPlacesProvider);
    final places = placesState.valueOrNull ?? const <TourismPlace>[];

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AI Travel Assistant'),
            Text(
              'Powered by UniSafeX destination data',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Open smart planner',
            onPressed: () => context.push(AppRoutes.tripPlanner),
            icon: const Icon(Icons.route_rounded),
          ),
          IconButton(
            tooltip: 'Clear conversation',
            onPressed: () => setState(() {
              _messages
                ..clear()
                ..add(
                  const _ChatMessage(
                    text: 'Conversation cleared. Where in India would you '
                        'like to explore?',
                    isUser: false,
                  ),
                );
            }),
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          if (placesState.isLoading) const LinearProgressIndicator(),
          _AssistantCapabilityStrip(
            count: places.length,
            cityCount: places.map((item) => item.city).toSet().length,
            isLoading: placesState.isLoading,
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _MessageBubble(
                message: _messages[index],
                onPlaceTap: (place) => context.push(
                  AppRoutes.placeDetail,
                  extra: place,
                ),
              ),
            ),
          ),
          if (_messages.length == 1)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _prompts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) => ActionChip(
                  label: Text(_prompts[index]),
                  onPressed: () => _send(_prompts[index], places),
                ),
              ),
            ),
          Container(
            padding: EdgeInsets.fromLTRB(
              14,
              10,
              14,
              10 + MediaQuery.paddingOf(context).bottom,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (value) => _send(value, places),
                    decoration: const InputDecoration(
                      hintText: 'Ask about travel in India...',
                      prefixIcon: Icon(Icons.auto_awesome),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                IconButton.filled(
                  tooltip: 'Send',
                  onPressed: () => _send(_controller.text, places),
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.places = const [],
  });

  final String text;
  final bool isUser;
  final List<TourismPlace> places;
}

class _AssistantCapabilityStrip extends StatelessWidget {
  const _AssistantCapabilityStrip({
    required this.count,
    required this.cityCount,
    required this.isLoading,
  });

  final int count;
  final int cityCount;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(
            isLoading ? Icons.sync_rounded : Icons.verified_rounded,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isLoading
                  ? 'Loading the full UniSafeX destination catalog for smarter answers...'
                  : 'Uses $count UniSafeX places across $cityCount cities for itinerary, safety, fees, timing, hidden gems and travel advice. No paid AI API connected yet.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.onPlaceTap,
  });

  final _ChatMessage message;
  final ValueChanged<TourismPlace> onPlaceTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.86,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: message.isUser
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(message.isUser ? 18 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? Colors.white : null,
                height: 1.45,
              ),
            ),
            if (message.places.isNotEmpty) ...[
              const SizedBox(height: 11),
              ...message.places.take(4).map(
                    (place) => InkWell(
                      onTap: () => onPlaceTap(place),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              color: AppColors.primary,
                              size: 19,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                '${place.name} · ${place.rating.toStringAsFixed(1)}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

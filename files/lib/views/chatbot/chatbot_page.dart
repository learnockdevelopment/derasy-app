import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../services/chatbot_service.dart';
import 'package:iconly/iconly.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({
    Key? key,
    this.embedded = false,
    this.onClose,
  }) : super(key: key);

  /// When true the page renders as a contained panel (no Scaffold/AppBar)
  /// so it can be embedded or shown as a draggable overlay.
  final bool embedded;

  /// Optional close callback used by the embedded panel header.
  final VoidCallback? onClose;

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // Layout helpers for embedded mode
  double get _panelWidth => 360.w.clamp(280.0, 420.0);
  double get _panelHeight => 520.h.clamp(420.0, 640.0);

  @override
  void dispose() {
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
    _focusNode.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    // Add user message
    final userMessage = ChatMessage(role: 'user', content: message);
    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      // Send to chatbot
      final response = await ChatbotService.sendMessage(message, _messages);
      setState(() {
        _messages.add(ChatMessage(role: 'assistant', content: response.reply));
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          role: 'assistant',
          content: 'Sorry, I encountered an error. Please try again.',
        ));
        _isLoading = false;
      });
      _scrollToBottom();
      Get.snackbar(
        'error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
    }
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h, left: isUser ? 40.w : 0, right: isUser ? 0 : 40.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isUser ? AppColors.blue1 : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
            bottomLeft: Radius.circular(isUser ? 20.r : 4.r),
            bottomRight: Radius.circular(isUser ? 4.r : 20.r),
          ),
        ),
        child: Text(
          message.content,
          style: AppFonts.bodyMedium.copyWith(
            color: isUser ? Colors.white : const Color(0xFF1F2937),
            
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h, left: 40.w, right: 40.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20.w,
              height: 20.h,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.blue1),
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              'typing'.tr,
              style: AppFonts.bodyMedium.copyWith(
                color: const Color(0xFF6B7280),
                
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesArea() {
    return Expanded(
      child: _messages.isEmpty && !_isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: AppColors.blue1.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: AppColors.blue1,
                      size: 40.sp,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'start_conversation'.tr,
                    style: AppFonts.bodyMedium.copyWith(
                      color: const Color(0xFF6B7280),
                      
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16.w),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  final message = _messages[index];
                  return _buildMessageBubble(message);
                } else {
                  return _buildTypingIndicator();
                }
              },
            ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border(
          top: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'type_message'.tr,
                    hintStyle: AppFonts.bodyMedium.copyWith(
                      color: const Color(0xFF9CA3AF),
                      
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
                  ),
                  style: AppFonts.bodyMedium.copyWith(fontSize: 14.sp),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.blue1,
                    AppColors.blue1.withOpacity(0.8),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: InkWell(
                onTap: _sendMessage,
                borderRadius: BorderRadius.circular(30.r),
                child: Container(
                  padding: EdgeInsets.all(12.w),
                  child: Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.blue1,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () => Get.back(),
      ),
      title: Text(
        'ai_assistant'.tr,
        style: AppFonts.bodyLarge.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          
        ),
      ),
    );
  }

  Widget _buildEmbeddedHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.blue1,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(14.r),
          topRight: Radius.circular(14.r),
        ),
      ),
      child: Row(
        children: [
          Text(
            'ai_assistant'.tr,
            style: AppFonts.bodyLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: widget.onClose,
            splashRadius: 20.r,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return SizedBox(
        width: _panelWidth,
        height: _panelHeight,
        child: Material(
          color: Colors.white,
          elevation: 12,
          borderRadius: BorderRadius.circular(14.r),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _buildEmbeddedHeader(),
              Expanded(
                child: Column(
                  children: [
                    _buildMessagesArea(),
                    _buildInputArea(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildMessagesArea(),
          _buildInputArea(),
        ],
      ),
    );
  }
}



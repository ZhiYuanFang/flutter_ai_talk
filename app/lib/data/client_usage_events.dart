// 客户端使用上报事件字典：稳定 featureId + 默认中文 description。
//
// 契约：POST /device/app/api/client-usage/report
// Body `{ featureId, description }`；二者勿含 `|`；须 Bearer；失败可丢；服务端约 3s 限流。

/// 单条上报事件（featureId 聚合键；description 运维可读）。
class ClientUsageEvent {
  const ClientUsageEvent(this.featureId, this.description);

  final String featureId;
  final String description;
}

/// 页展示与动作事件常量（动态描述由调用方格式化）。
abstract final class ClientUsageEvents {
  // —— 主壳 PageView ——
  static const feedingShow =
      ClientUsageEvent('page_feeding_show', '展示喂养页');
  static const predictionShow =
      ClientUsageEvent('page_prediction_show', '展示智能预测页');
  static const ucgShellShow =
      ClientUsageEvent('page_ucg_shell_show', '展示 UCG 壳页');

  // —— UCG 子表面 ——
  static const ucgSquareShow =
      ClientUsageEvent('page_ucg_square_show', '展示 UCG 广场');
  static const ucgMessagesShow =
      ClientUsageEvent('page_ucg_messages_show', '展示 UCG 消息页');
  static const ucgProfileShow =
      ClientUsageEvent('page_ucg_profile_show', '展示 UCG 我的页');
  static const ucgComposeShow =
      ClientUsageEvent('page_ucg_compose_show', '展示发布动态页');

  // —— 路由页 ——
  static const settingsShow =
      ClientUsageEvent('page_settings_show', '展示设置页');
  static const bindBabyShow =
      ClientUsageEvent('page_bind_baby_show', '展示绑定宝宝页');
  static const babyProfileShow =
      ClientUsageEvent('page_baby_profile_show', '展示宝宝资料页');
  static const feedbackShow =
      ClientUsageEvent('page_feedback_show', '展示反馈页');
  static const changePasswordShow =
      ClientUsageEvent('page_change_password_show', '展示修改密码页');
  static const aiAnalysisShow =
      ClientUsageEvent('page_ai_analysis_show', '展示 AI 分析页');
  static const feedingAnalysisShow =
      ClientUsageEvent('page_feeding_analysis_show', '展示喂养分析页');
  static const growthShow =
      ClientUsageEvent('page_growth_show', '展示成长轨迹页');
  static const careAlertShow =
      ClientUsageEvent('page_care_alert_show', '展示值得留意详情页');
  static const unlockHubShow =
      ClientUsageEvent('page_unlock_hub_show', '展示功能开通中心');
  static const inviteHowtoShow =
      ClientUsageEvent('page_invite_howto_show', '展示邀请码说明页');
  static const vipPurchaseShow =
      ClientUsageEvent('page_vip_purchase_show', '展示 VIP 购买页');
  static const trendsShow =
      ClientUsageEvent('page_trends_show', '展示趋势页');
  static const widgetShowcaseShow =
      ClientUsageEvent('page_widget_showcase_show', '展示小组件秀页');
  static const companionShow =
      ClientUsageEvent('page_companion_show', '展示陪伴页');
  static const xiaozhiSpeakerShow =
      ClientUsageEvent('page_xiaozhi_speaker_show', '展示小智音箱页');

  // —— 横屏展示 ——
  static const predictionLandscapeCast = ClientUsageEvent(
    'page_prediction_landscape_cast',
    '预测页进入投屏横屏',
  );
  static const trendsLandscapeShow = ClientUsageEvent(
    'page_trends_landscape_show',
    '趋势页旋转进入横屏',
  );

  // —— 语音习惯（竖横共用 controller）——
  static const voiceWakeKws =
      ClientUsageEvent('voice_wake_kws', '语音唤醒');
  static const voiceWakeTap =
      ClientUsageEvent('voice_wake_tap', '点击唤醒');
  static const voiceWakeBargeIn =
      ClientUsageEvent('voice_wake_barge_in', '语音打断思考');

  /// 仅用户 ASR；超长截断；空串调用方勿报。
  static ClientUsageEvent voiceTurnUser(String userText) {
    const prefix = '语音对话（用户）：';
    final body = _sanitizeDescPart(userText);
    return ClientUsageEvent('voice_turn_user', '$prefix$body');
  }

  // —— 小智点击漏斗（点击即报）——
  static const xiaozhiAddBtnClick =
      ClientUsageEvent('xiaozhi_add_btn_click', '点击添加音箱');
  static const xiaozhiConsoleLinkClick =
      ClientUsageEvent('xiaozhi_console_link_click', '点击小智控制台链接');
  static const xiaozhiBuyHelpClick =
      ClientUsageEvent('xiaozhi_buy_help_click', '点击如何购买说明');
  static const xiaozhiAddDialogSubmitClick = ClientUsageEvent(
    'xiaozhi_add_dialog_submit_click',
    '点击添加弹窗确认',
  );

  // —— AI 分析点击（点击即报）——
  static const feedingAnalyzeBtnClick =
      ClientUsageEvent('feeding_analyze_btn_click', '点击AI智能分析');

  // —— 消息通知偏好 ——
  static const notificationPrefOn =
      ClientUsageEvent('notification_pref_on', '开启消息通知');
  static const notificationPrefOff =
      ClientUsageEvent('notification_pref_off', '关闭消息通知');

  // —— 动作：稳定 featureId；description 由工厂生成 ——
  static const predictionToggleOnId = 'prediction_card_toggle_on';
  static const predictionToggleOffId = 'prediction_card_toggle_off';

  static ClientUsageEvent predictionToggleOn({
    required int order,
    required String eventLabel,
  }) {
    final label = _sanitizeDescPart(eventLabel);
    return ClientUsageEvent(
      predictionToggleOnId,
      '开启预测开关（顺序 $order·$label）',
    );
  }

  static ClientUsageEvent predictionToggleOff({
    required int order,
    required String eventLabel,
  }) {
    final label = _sanitizeDescPart(eventLabel);
    return ClientUsageEvent(
      predictionToggleOffId,
      '关闭预测开关（顺序 $order·$label）',
    );
  }

  static ClientUsageEvent predictionLayoutToList() => const ClientUsageEvent(
        'prediction_layout_list',
        '预测页切换为纵向列表',
      );

  static ClientUsageEvent predictionLayoutToGrid() => const ClientUsageEvent(
        'prediction_layout_grid',
        '预测页切换为瀑布流',
      );

  static ClientUsageEvent ucgSquareLayoutToList() => const ClientUsageEvent(
        'ucg_square_layout_list',
        'UCG 广场切换为列表',
      );

  static ClientUsageEvent ucgSquareLayoutToWaterfall() =>
      const ClientUsageEvent(
        'ucg_square_layout_waterfall',
        'UCG 广场切换为瀑布流',
      );

  static const themePaletteOpen =
      ClientUsageEvent('theme_palette_open', '点击主题色入口');

  static ClientUsageEvent themeChangeOk(String themeLabel) => ClientUsageEvent(
        'theme_change_ok',
        '主题色切换成功（${_sanitizeDescPart(themeLabel)}）',
      );

  static const babyAvatarChangeOk =
      ClientUsageEvent('baby_avatar_change_ok', '更换宝宝头像成功');

  /// 去掉 description 中的非法 `|`，避免污染服务端时间线分隔。
  static String _sanitizeDescPart(String raw) {
    final t = raw.trim().replaceAll('|', '/');
    if (t.isEmpty) return '-';
    return t.length > 64 ? t.substring(0, 64) : t;
  }
}

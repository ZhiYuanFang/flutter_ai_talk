## 1. 依赖与组件骨架

- [x] 1.1 在 `app/pubspec.yaml` 引入 Markdown 渲染依赖（优先 `markdown_widget`；若 Web 不通过则换 `flutter_markdown_plus` 等等价包），执行 `flutter pub get`
- [x] 1.2 新增 `app/lib/ui/widgets/clinic_answer_body.dart`：`ClinicAnswerBody(text, streaming)` 封装流式 `Text` 与完成后 Markdown 分支

## 2. Markdown 样式与语法子集

- [x] 2.1 在 `ClinicAnswerBody` 内配置 Theme 派生样式表（标题 `#`–`###`、正文 `bodyMedium`、粗体、列表缩进、`---` 分隔线）
- [x] 2.2 禁用链接点击：链接语法仅渲染可见文字，不注册 `onTapLink` / 不使用 `url_launcher`
- [x] 2.3 确认 Tier 3/4 语法（表格、图片、围栏代码块）降级不引发布局异常

## 3. 接入胖宝诊疗页

- [x] 3.1 在 `pangbao_ai_screen.dart` 计算 `isStreamingAnswer`（`_activeAssistant` + `_busy` + answer 非空）
- [x] 3.2 将答案气泡内 `Text(item.answer)` 替换为 `ClinicAnswerBody`；`session_sync` 历史与 `answer_done` 后共用
- [x] 3.3 确认 `thinking` 块、用户气泡、免责声明仍为纯 `Text`，未误用 Markdown 组件

## 4. 验证

- [ ] 4.1 Web：`flutter run -d chrome` 发送诊疗问题，流式阶段见纯文本（含 `###`/`*` 等），完成后见标题/粗体/列表/分隔线
- [ ] 4.2 重进页面触发 `session_sync`，历史答案 Markdown 展示与完成后一致
- [ ] 4.3 深色主题下答案气泡内文字对比度可读
- [ ] 4.4 含 `[文字](url)` 的答案仅显示文字，点击不打开外链

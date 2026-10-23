// ============================================================
// glog + gflags 学习示例
//
// 运行方式:
//   ./demo                               # 默认参数，日志写到 /tmp/demo_info_*
//   ./demo --help                        # 查看 gflags 自动生成的参数帮助
//   ./demo --name=Bob --count=5          # 传自定义参数
//   ./demo --v=1 --alsologtostderr       # 打开 VLOG，日志同时打到屏幕
// ============================================================
#include <glog/logging.h>
#include <gflags/gflags.h>

#include <iostream>

// ---------------- gflags: 定义命令行参数 ----------------
// 语法: DEFINE_类型(名字, 默认值, "帮助说明")
// 定义之后就能用 FLAGS_name / FLAGS_count / FLAGS_verbose 访问
DEFINE_string(name, "world", "被问候的名字");
DEFINE_int32(count, 3, "问候次数");
DEFINE_bool(verbose, false, "是否输出更多细节");

int main(int argc, char* argv[]) {
  // 1. 初始化 glog（写日志之前必须先调用）
  google::InitGoogleLogging(argv[0]);

  // 2. 解析命令行参数（把 --xxx 形式的 flag 提取出来，
  //    第三个参数 true 表示解析后从 argv 里移除，剩下的是普通参数）
  gflags::ParseCommandLineFlags(&argc, &argv, true);

  // 3. 让 INFO 级别日志写到 /tmp/demo_info_ 开头的文件
  //    （默认会写到 /tmp/<程序名>.<主机名>.<用户名>.log.INFO.xxx，
  //      这里指定前缀更直观好找）
  google::SetLogDestination(google::INFO, "/tmp/demo_info_");

  // 4. 使用 gflags 定义的参数
  for (int i = 1; i <= FLAGS_count; ++i) {
    LOG(INFO) << "Hello, " << FLAGS_name << "! (" << i << "/" << FLAGS_count << ")";
  }
  if (FLAGS_verbose) {
    LOG(INFO) << "verbose 开关已打开，多输出点细节";
  }

  // 5. 日志级别：INFO < WARNING < ERROR < FATAL
  LOG(INFO) << "INFO: 普通信息";
  LOG(WARNING) << "WARNING: 警告";
  LOG(ERROR) << "ERROR: 错误";
  // LOG(FATAL) << "FATAL: 输出后程序立即退出";  // 取消注释试试

  // 6. VLOG: 详细日志，默认不显示，运行时加 --v=1 才输出
  VLOG(1) << "这条只有 --v=1 或 --v=2 时才显示";

  // 7. CHECK 系列断言：条件不满足立刻报错退出
  //    （比 assert 强：Release 编译也生效）
  CHECK_GT(FLAGS_count, 0) << "count 必须大于 0";

  // 8. 条件日志：条件成立才输出
  LOG_IF(INFO, FLAGS_name == "world") << "名字还是默认值 world";

  // 9. 限频日志：每 3 次输出一次（放在循环里效果明显）
  for (int i = 0; i < 10; ++i) {
    LOG_EVERY_N(INFO, 3) << "每 3 次输出一次: " << i;
  }

  // 10. DLOG: 只在 Debug 编译（未定义 NDEBUG）时生效
  //     本示例编译时没加 -DNDEBUG（相当于 Debug），所以能看到我；
  //     加 -DNDEBUG 编译（Release）时这行会被编译器直接删掉
  DLOG(INFO) << "Release 编译（-DNDEBUG）时看不到我";

  // 11. ParseCommandLineFlags 之后 argv 里剩下的是普通参数
  std::cout << "[stdout] 剩下的普通参数个数: " << (argc - 1) << std::endl;

  google::ShutdownGoogleLogging();
  return 0;
}

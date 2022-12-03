#include <atomic>
#include <iostream>
#include <sys/sysctl.h>
#include <thread>

static void enable_tso(bool enable_) {
  int enable = int(enable_);
  size_t size = sizeof(enable);
  int err = 0; // sysctlbyname("kern.tso_enable", NULL, &size, &enable, size);
  assert(err == 0);
}

int main(int argc, char **argv) {
  bool useTSO = false;
  if (argc > 1) {
    useTSO = std::stoi(std::string(argv[1])) == 1 ? true : false;
  }
  std::cout << "TSO is " << (useTSO ? "enabled" : "disabled") << std::endl;

  std::atomic<int> flag(0);
  int sharedValue = 0;
  auto counter = [&](bool enable) {
    enable_tso(enable);
    int count = 0;
    while (count < 10000000) {
      int expected = 0;
      if (flag.compare_exchange_strong(expected, 1,
                                       std::memory_order_relaxed)) {
        // Lock was successful
        sharedValue++;
        flag.store(0, std::memory_order_relaxed);
        count++;
      }
    }
  };

  std::thread thread1([&]() { counter(useTSO); });
  std::thread thread2([&]() { counter(useTSO); });
  thread2.join();
  thread1.join();

  std::cout << sharedValue << std::endl;
}

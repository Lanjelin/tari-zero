#include <stdio.h>

int main() {
  puts("");
  puts("🧱 This image contains multiple Tari components.");
  puts("");
  puts("👉 Use docker run --entrypoint to select one of the following:");
  puts("   - wallet");
  puts("   - merge_mining_proxy");
  puts("   - miner");
  puts("   - node");
  puts("   - node-metrics");
  puts("");
  puts("📦 Example:");
  puts("   docker run --rm -it --entrypoint wallet my-tari-image");
  puts("");
  return 1;
}

#!/bin/bash

set -e

echo "=============================="
echo "JaCoCo 运行时覆盖率导出工具"
echo "=============================="

CONTAINER_NAME=${1:-"food-delivery-backend"}
OUTPUT_DIR=${2:-"./jacoco-runtime"}
JACOCO_CLI_VERSION="0.8.11"

mkdir -p "${OUTPUT_DIR}"

echo "[1/4] 下载 JaCoCo CLI 工具..."
if [ ! -f "${OUTPUT_DIR}/jacococli.jar" ]; then
    curl -sL "https://repo1.maven.org/maven2/org/jacoco/org.jacoco.cli/${JACOCO_CLI_VERSION}/org.jacoco.cli-${JACOCO_CLI_VERSION}-nodeps.jar" -o "${OUTPUT_DIR}/jacococli.jar"
fi

echo "[2/4] 从运行中的容器导出覆盖率数据..."
docker exec "${CONTAINER_NAME}" ls /jacoco-data/ 2>/dev/null || {
    echo "容器 ${CONTAINER_NAME} 未运行或无覆盖率数据目录"
    echo "尝试通过 TCP 端口导出..."
    java -jar "${OUTPUT_DIR}/jacococli.jar" dump \
        --address localhost \
        --port 6300 \
        --destfile "${OUTPUT_DIR}/jacoco-runtime.exec" \
        --quiet
    echo "✓ 通过 TCP 6300 端口导出成功"
}

if [ -f "${OUTPUT_DIR}/jacoco-runtime.exec" ]; then
    echo "覆盖率数据已存在: ${OUTPUT_DIR}/jacoco-runtime.exec"
else
    docker cp "${CONTAINER_NAME}:/jacoco-data/jacoco.exec" "${OUTPUT_DIR}/jacoco-runtime.exec" 2>/dev/null || {
        echo "⚠ 容器中暂无覆盖率数据，JVM退出时会自动生成"
    }
fi

echo "[3/4] 生成覆盖率报告..."
if [ -f "${OUTPUT_DIR}/jacoco-runtime.exec" ] && [ -f target/*.jar ]; then
    java -jar "${OUTPUT_DIR}/jacococli.jar" report \
        "${OUTPUT_DIR}/jacoco-runtime.exec" \
        --classfiles target/classes \
        --sourcefiles src/main/java \
        --html "${OUTPUT_DIR}/report" \
        --xml "${OUTPUT_DIR}/jacoco.xml" \
        --csv "${OUTPUT_DIR}/jacoco.csv"
    echo "✓ 覆盖率报告已生成: ${OUTPUT_DIR}/report/index.html"
fi

echo "[4/4] 汇总统计..."
if [ -f "${OUTPUT_DIR}/jacoco.csv" ]; then
    echo ""
    echo "运行时代码覆盖率统计:"
    awk -F',' '
        NR > 1 {
            missed += $4
            covered += $5
        }
        END {
            if (missed + covered > 0) {
                ratio = covered * 100 / (missed + covered)
                printf "  总指令覆盖率: %.2f%% (%d / %d)\n", ratio, covered, missed + covered
            }
        }
    ' "${OUTPUT_DIR}/jacoco.csv"
fi

echo ""
echo "=============================="
echo "完成！"
echo "报告位置: ${OUTPUT_DIR}/report/index.html"
echo "=============================="

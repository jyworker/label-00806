# 多阶段构建 - 支持 ARM64 和 AMD64
FROM --platform=$BUILDPLATFORM maven:3.9-eclipse-temurin-17 AS builder

WORKDIR /app

# 复制 pom.xml 并下载依赖
COPY pom.xml .
RUN mvn dependency:go-offline -B

# 下载 JaCoCo agent
RUN mvn org.apache.maven.plugins:maven-dependency-plugin:3.6.1:copy \
  -Dartifact=org.jacoco:jacocoagent:0.8.11:jar \
  -DoutputDirectory=/app

# 复制源码并构建
COPY src ./src
RUN mvn clean package -DskipTests -B

# 运行阶段 - 使用跨平台基础镜像
FROM eclipse-temurin:17-jre

WORKDIR /app

# 设置时区为上海
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 从构建阶段复制 jar 包
COPY --from=builder /app/target/*.jar app.jar

# 从构建阶段复制 JaCoCo agent
COPY --from=builder /app/jacocoagent-0.8.11.jar jacocoagent.jar

# 暴露端口
EXPOSE 8080

# 暴露 JaCoCo 端口（可选，用于远程收集覆盖率）
EXPOSE 6300

# 启动命令 - 支持通过环境变量启用 JaCoCo
CMD java -Duser.timezone=Asia/Shanghai \
  ${JAVA_OPTS} \
  ${JACOCO_ENABLED:+-javaagent:jacocoagent.jar=output=tcpserver,port=6300,address=*,includes=com.fooddelivery.*} \
  -jar app.jar

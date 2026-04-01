# 多阶段构建 - 支持 ARM64 和 AMD64
FROM --platform=$BUILDPLATFORM maven:3.9-eclipse-temurin-17 AS builder

WORKDIR /app

# 复制 pom.xml 并下载依赖
COPY pom.xml .
RUN mvn dependency:go-offline -B

# 复制源码并构建
COPY src ./src
RUN mvn clean package -DskipTests -B

# 运行阶段 - 使用跨平台基础镜像
FROM eclipse-temurin:17-jre

WORKDIR /app

# 设置时区为上海
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 创建覆盖率数据目录
RUN mkdir -p /app/jacoco

# 从构建阶段复制 jar 包
COPY --from=builder /app/target/*.jar app.jar

# 从maven仓库复制JaCoCo agent
COPY --from=builder /root/.m2/repository/org/jacoco/org.jacoco.agent/0.8.11/org.jacoco.agent-0.8.11-runtime.jar jacoco-agent.jar

# 暴露应用端口和JaCoCo dump端口
EXPOSE 8080 6300

# 启动命令 - 添加JVM时区参数和JaCoCo运行时覆盖率
ENTRYPOINT ["java", \
    "-Duser.timezone=Asia/Shanghai", \
    "-javaagent:/app/jacoco-agent.jar=destfile=/app/jacoco/jacoco-runtime.exec,append=true,includes=com.fooddelivery.*,dumponexit=true,output=tcpserver,address=0.0.0.0,port=6300", \
    "-jar", "app.jar"]

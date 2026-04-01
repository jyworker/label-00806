# 多阶段构建 - 支持 ARM64 和 AMD64
FROM --platform=$BUILDPLATFORM maven:3.9-eclipse-temurin-17 AS builder

WORKDIR /app

# 复制 pom.xml 并下载依赖
COPY pom.xml .
RUN mvn dependency:go-offline -B && \
    mvn dependency:copy -Dartifact=org.jacoco:org.jacoco.agent:0.8.11:jar:runtime -DoutputDirectory=./jacoco

# 复制源码并构建
COPY src ./src
RUN mvn clean package -DskipTests -B

# 运行阶段 - 使用跨平台基础镜像
FROM eclipse-temurin:17-jre

WORKDIR /app

# 设置时区为上海
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    mkdir -p /jacoco-data

# 从构建阶段复制 jar 包和 JaCoCo agent
COPY --from=builder /app/target/*.jar app.jar
COPY --from=builder /app/jacoco/*.jar jacoco-agent.jar

# 暴露应用端口 + JaCoCo dump 端口
EXPOSE 8080 6300

# 启动命令 - 集成 JaCoCo agent 支持运行时覆盖率收集
# output=tcpserver: 支持通过 6300 端口远程 dump 覆盖率数据
# destfile: 容器退出时输出覆盖率数据
ENTRYPOINT ["java", \
    "-Duser.timezone=Asia/Shanghai", \
    "-javaagent:jacoco-agent.jar=destfile=/jacoco-data/jacoco.exec,output=tcpserver,address=0.0.0.0,port=6300,append=true", \
    "-jar", "app.jar"]

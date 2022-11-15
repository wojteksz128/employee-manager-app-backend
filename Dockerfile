### STAGE 1: Build ###
FROM eclipse-temurin:17-jdk-alpine as build
WORKDIR /workspace/app
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .
COPY src src
RUN ./mvnw install -DskipTests
RUN mkdir -p target/dependency && (cd target/dependency; jar -xf ../*.jar)

### STAGE 2: Extract ###
FROM eclipse-temurin:17-jdk-alpine as extract
WORKDIR /workspace/app
COPY --from=build /workspace/app/target .
RUN mkdir -p target/extracted
RUN java -Djarmode=layertools -jar *.jar extract --destination target/extracted

### STAGE 3: Run ###
FROM eclipse-temurin:17-jdk-alpine
WORKDIR /workspace/app
VOLUME /tmp
ARG EXTRACTED=/workspace/app/target/extracted
COPY --from=extract $EXTRACTED/dependencies/ ./
COPY --from=extract $EXTRACTED/spring-boot-loader/ ./
COPY --from=extract $EXTRACTED/snapshot-dependencies/ ./
COPY --from=extract $EXTRACTED/application/ ./
EXPOSE 8080
ENTRYPOINT ["java","org.springframework.boot.loader.JarLauncher"]

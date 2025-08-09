# Minimal Java WebApp for WebLogic

This is a minimalistic Java servlet web application for deployment on Oracle WebLogic Server.

## Structure

- `src/main/java/com/example/HelloServlet.java`: Simple servlet responding with "Hello, WebLogic!"
- `src/main/webapp/WEB-INF/web.xml`: Deployment descriptor mapping `/hello` to the servlet.
- `pom.xml`: Maven build file to produce `sample.war`.

## Build Instructions

1. Install [Maven](https://maven.apache.org/install.html) if not already available.
2. Run the following command in this directory:

   ```shell
   export JAVA_HOME=/usr/java/latest
   mvn clean package
   ```

3. The WAR file will be generated at `target/sample.war`.

## Deploy

- Deploy `sample.war` to your WebLogic Server using the Admin Console (recommended for production) or the autodeploy folder (for quick testing).
- For reliable access, ensure the application is shown as 'Active' in the Admin Console after installation.
- Access the servlet at `http://<server>:<port>/sample/hello`

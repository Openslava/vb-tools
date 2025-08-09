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

### Initial Deployment:
- Deploy `sample.war` to your WebLogic Server using the Admin Console (recommended for production) or the autodeploy folder (for quick testing).
- For reliable access, ensure the application is shown as 'Active' in the Admin Console after installation.

### Redeploying New Versions:
1. **Build the new version**: Run `mvn clean package` to create updated `sample.war`
2. **Access Admin Console**: Go to `http://localhost:7001/console`
3. **Navigate to Deployments**: Click `Deployments` in the left menu
4. **Select your application**: Click on `sample` in the deployments list
5. **Update the application**: 
   - Click the `Update` button
   - Choose `Replace the current deployment with a new version`
   - Click `Next`
6. **Upload new WAR**: 
   - Click `Browse` and select your new `target/sample.war`
   - Click `Next` → `Next` → `Finish`
7. **Verify deployment**: Ensure the application shows as 'Active' and test the changes

### Quick Testing:
- Access the servlet at `http://<server>:<port>/sample/hello`
- Check the version number to confirm your changes are deployed

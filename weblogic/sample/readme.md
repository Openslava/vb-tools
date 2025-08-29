# WebLogic Sample App ☕

Minimal Java servlet web application for Oracle WebLogic Server.

## Structure

- `src/main/java/com/example/HelloServlet.java` - Simple servlet
- `src/main/webapp/WEB-INF/web.xml` - Deployment descriptor
- `pom.xml` - Maven build configuration

## 🔨 Build

```bash
export JAVA_HOME=/usr/java/latest
mvn clean package
```

Output: `target/sample.war`

## Deploy

### Initial Deployment

1. Open WebLogic Admin Console: <http://localhost:7001/console>
2. Navigate: **Deployments** → **Install**
3. Upload `target/sample.war`
4. Test: <http://localhost:7001/sample/hello>

### Update Existing

1. **Deployments** → Select `sample` → **Update**
2. Choose "Replace with new version"
3. Upload new `target/sample.war`
4. **Finish** → Verify status **Active**

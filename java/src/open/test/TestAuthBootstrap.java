package com.easydataservices.open.test;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;
import java.util.logging.Logger;
import com.easydataservices.open.auth.util.Mask;
import com.easydataservices.open.test.TestAuthPayload;

/**
 * Test bootstrap class. Used to set up and execute AUTH Service tests.
 *
 * @author jeremy.rickard@easydataservices.com
 */
public class TestAuthBootstrap {
  private static final String className = TestAuthBootstrap.class.getName();
  private static final Logger logger = Logger.getLogger(className);
  private String payloadClassName;
  private String payloadUniqueId;
  private int payloadIterations;
  private int payloadIntervalMs;
  private String payloadAltId;
  private String dbUrl;
  private String dbSchema;
  private String dbUser;
  private String dbPassword;
  private Connection connection;

  public Connection getConnection() {
    return connection;
  }

  public String getDbSchema() {
    return dbSchema;
  }

  public String getPayloadClassName() {
    return payloadClassName;
  }

  public String getPayloadUniqueId() {
    return payloadUniqueId;
  }

  public int getPayloadIterations() {
    return payloadIterations;
  }

  public int getPayloadIntervalMs() {
    return payloadIntervalMs;
  }

  public String getPayloadAltId() {
    return payloadAltId;
  }

  private final void readDbConfig() {
    logger.info(() -> String.format("Reading database config properties..."));
    try (InputStream inputStream = new FileInputStream("db_config.properties")) {
      Properties properties = new Properties();
      properties.load(inputStream);
      dbUrl=properties.getProperty("db.url");
      dbSchema=properties.getProperty("db.schema");
      dbUser=properties.getProperty("db.user");
      dbPassword=properties.getProperty("db.password");
      logger.finer(() -> String.format("db.url=%s", dbUrl));
      logger.finer(() -> String.format("db.schema=%s", dbSchema));
      logger.finer(() -> String.format("db.user=%s", dbUser));
      logger.finer(() -> String.format("db.password=%s", Mask.last(dbPassword, 0)));
    }
    catch (IOException exception) {
      logger.severe(() -> String.format("FAILED: %s", exception.toString()));
      System.exit(4);
    }
  }

  private final void readPayloadConfig(String fileName) {
    logger.info(() -> String.format("Reading payload config properties from file %s...", fileName));
    try (InputStream inputStream = new FileInputStream(fileName)) {
      Properties properties = new Properties();
      properties.load(inputStream);
      payloadClassName=properties.getProperty("payload.payloadClassName");
      payloadUniqueId=properties.getProperty("payload.uniqueId");
      payloadIterations=Integer.parseInt(properties.getProperty("payload.iterations"));
      payloadIntervalMs=Integer.parseInt(properties.getProperty("payload.intervalMs"));
      payloadAltId=properties.getProperty("payload.alternativeId");
      logger.finer(() -> String.format("payload.payloadClassName=%s", payloadClassName));
      logger.finer(() -> String.format("payload.uniqueId=%s", payloadUniqueId));
      logger.finer(() -> String.format("payload.iterations=%s", payloadIterations));
      logger.finer(() -> String.format("payload.intervalMs=%s", payloadIntervalMs));
      logger.finer(() -> String.format("payload.alternativeId=%s", payloadAltId));
    }
    catch (Exception exception) {
      logger.severe(() -> String.format("FAILED: %s", exception.toString()));
      System.exit(4);
    }
  }

  private final void connect() {
    logger.info(() -> String.format("Connecting to database..."));
    try {
      connection = DriverManager.getConnection(dbUrl + ":user=" + dbUser + ";password=" + dbPassword + ";");
    }
    catch (SQLException exception) {
      logger.severe(() -> String.format("FAILED: %s", exception.toString()));
      System.exit(4);
    }    
  }

  protected final void cleanup() {
    logger.info(() -> String.format("Cleaning up resources..."));
    try {
      connection.close();
    }
    catch (SQLException exception) {
      logger.severe(() -> String.format("FAILED: %s", exception.toString()));
      System.exit(4);
    }    
  }

  public static void main(String[] args) {
    TestAuthBootstrap bootstrap = new TestAuthBootstrap();
    bootstrap.readPayloadConfig(args[0]);
    try {
      bootstrap.readDbConfig();
      Class payloadClass = Class.forName(bootstrap.getPayloadClassName());
      TestAuthPayload payloadClassInstance = (TestAuthPayload) payloadClass.newInstance();
      bootstrap.connect();
      payloadClassInstance.init(bootstrap);
      logger.info(() -> String.format("Executing payload %s time(s) at %s ms intervals...", 
      bootstrap.getPayloadIterations(), bootstrap.getPayloadIntervalMs()));
      int iteration = 0;
      while (iteration < bootstrap.getPayloadIterations()) {
        logger.fine("Executing payload iteration " + iteration + "...");
        payloadClassInstance.payload(iteration);
        if (bootstrap.getPayloadIntervalMs() > 0) {
          Thread.sleep(bootstrap.getPayloadIntervalMs());
        }
        iteration = iteration + 1;
      }      
      bootstrap.cleanup();
    }
    catch (Exception exception) {
      logger.severe(() -> String.format("FAILED: %s", exception.toString()));
      System.exit(4);
    }
  }  
}

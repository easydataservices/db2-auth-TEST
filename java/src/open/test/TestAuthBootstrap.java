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
  private Connection connection;
  private String dbUrl;
  private String dbSchema;
  private String dbUser;
  private String dbPassword;
  private String payloadClassName;
  private int payloadRangeStart;
  private int payloadRangeEnd;
  private int payloadRangeIncrement;
  private int payloadIntervalMs;
  private int payloadIterations;
  private int payloadIterationDelayMs;
  private String payloadPrefix1;
  private String payloadPrefix2;

  public Connection getConnection() {
    return connection;
  }

  public String getDbSchema() {
    return dbSchema;
  }

  public String getPayloadPrefix1() {
    return payloadPrefix1;
  }

  public String getPayloadPrefix2() {
    return payloadPrefix2;
  }

  private String getPayloadClassName() {
    return payloadClassName;
  }

  private int getPayloadRangeStart() {
    return payloadRangeStart;
  }

  private int getPayloadRangeEnd() {
    return payloadRangeEnd;
  }

  private int getPayloadRangeIncrement() {
    return payloadRangeIncrement;
  }

  private int getPayloadIterations() {
    return payloadIterations;
  }

  private int getPayloadIntervalMs() {
    return payloadIntervalMs;
  }

  private int getPayloadIterationDelayMs() {
    return payloadIterationDelayMs;
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
      payloadClassName=properties.getProperty("payload.className", "");
      payloadRangeStart=Integer.parseInt(properties.getProperty("payload.rangeStart", "1"));
      payloadRangeEnd=Integer.parseInt(properties.getProperty("payload.rangeEnd", "1"));
      payloadRangeIncrement=Integer.parseInt(properties.getProperty("payload.rangeIncrement", "1"));
      payloadIntervalMs=Integer.parseInt(properties.getProperty("payload.intervalMs", "0"));
      payloadIterations=Integer.parseInt(properties.getProperty("payload.iterations", "1"));
      payloadIterationDelayMs=Integer.parseInt(properties.getProperty("payload.iterationDelayMs", "0"));
      payloadPrefix1=properties.getProperty("payload.prefix1", "SESSION");
      payloadPrefix2=properties.getProperty("payload.prefix2", "USER");
      if (payloadClassName.trim().equals("")) {
        throw new IllegalArgumentException("Property payload.className must be specified.");
      }
      if (payloadRangeIncrement == 0) {
        throw new IllegalArgumentException("Property payload.rangeIncrement cannot be 0.");
      }
      logger.finer(() -> String.format("payload.className=%s", payloadClassName));
      logger.finer(() -> String.format("payload.rangeStart=%s", payloadRangeStart));
      logger.finer(() -> String.format("payload.rangeEnd=%s", payloadRangeEnd));
      logger.finer(() -> String.format("payload.rangeIncrement=%s", payloadRangeIncrement));
      logger.finer(() -> String.format("payload.intervalMs=%s", payloadIntervalMs));
      logger.finer(() -> String.format("payload.iterations=%s", payloadIterations));
      logger.finer(() -> String.format("payload.iterationDelayMs=%s", payloadIterationDelayMs));
      logger.finer(() -> String.format("payload.prefix1=%s", payloadPrefix1));
      logger.finer(() -> String.format("payload.prefix2=%s", payloadPrefix2));
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
      int iteration = 1;
      while (iteration <= bootstrap.getPayloadIterations()) {
        logger.fine("Starting payload iteration " + iteration + "...");
        int rangeValue = bootstrap.getPayloadRangeStart();
        while (rangeValue <= bootstrap.getPayloadRangeEnd() && rangeValue >= bootstrap.getPayloadRangeStart()) {
          logger.fine("Executing payload for iteration " + iteration + ", range value " + rangeValue + "...");
          try {
            payloadClassInstance.payload(rangeValue, iteration);
          }
          catch (SQLException exception) {
            logger.severe(() -> String.format("FAILED: %s", exception.getMessage()));
          }
          rangeValue = rangeValue + bootstrap.getPayloadRangeIncrement();
          if (bootstrap.getPayloadIntervalMs() > 0) {
            Thread.sleep(bootstrap.getPayloadIntervalMs());
          }
        }
        if (bootstrap.getPayloadIntervalMs() > 0) {
          Thread.sleep(bootstrap.getPayloadIterationDelayMs());
        }
        iteration = iteration + 1;
      }      
      bootstrap.cleanup();
    }
    catch (Exception exception) {
      logger.severe(() -> String.format("ABORT: %s", exception.getMessage()));
      System.exit(4);
    }
  }  
}

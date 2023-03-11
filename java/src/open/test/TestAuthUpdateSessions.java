package com.easydataservices.open.test;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.logging.Logger;
import com.easydataservices.open.auth.AuthControlDao;
import com.easydataservices.open.auth.AuthSessionDao;
import com.easydataservices.open.auth.StoreSession;
import com.easydataservices.open.auth.StoreAttribute;
import com.easydataservices.open.test.TestAuthBootstrap;
import com.easydataservices.open.test.TestAuthPayload;

/**
 * AUTH Service test payload class for updating sessions.
 *
 * @author jeremy.rickard@easydataservices.com
 */
public class TestAuthUpdateSessions extends TestAuthPayload {
  private static final String className = TestAuthUpdateSessions.class.getName();
  private static final Logger logger = Logger.getLogger(className);
  private AuthSessionDao authSessionDao;
  private AuthControlDao authControlDao;
  private String sessionIdPrefix;
  private String authNamePrefix;

  public void init(TestAuthBootstrap bootstrap) throws Exception {
    logger.finer(() -> String.format("ENTRY %s %s", this, bootstrap));
    authSessionDao = new AuthSessionDao(bootstrap.getConnection(), bootstrap.getDbSchema());
    authControlDao = new AuthControlDao(bootstrap.getConnection(), bootstrap.getDbSchema());
    sessionIdPrefix = bootstrap.getPayloadPrefix1() + "_";
    if (!bootstrap.getPayloadPrefix2().trim().equals("")) {
      authNamePrefix = bootstrap.getPayloadPrefix2() + "_";
    }
    logger.finer(() -> String.format("RETURN %s", this));
  }

  public void payload(int rangeValue, int iteration) throws Exception {
    logger.finer(() -> String.format("ENTRY %s %s %s", this, rangeValue, iteration));
    ArrayList<StoreAttribute> attributeList = new ArrayList<StoreAttribute>();
    String sessionId = sessionIdPrefix + rangeValue;
    StoreSession session = authSessionDao.getSession(sessionId);
    if (session == null) {
      logger.info(() -> String.format("%s %s", this, "Session " + sessionId + " does not exist."));
    }
    else {
      String authName = session.getAuthName();
      if (authName == null && authNamePrefix != null) {
        authName = authNamePrefix + rangeValue;
      }
      authControlDao.changeSessionConfig(
        sessionId,
        new Object[] {
          null,
          authName,
          30,
          "{\"comment\":\"Updated by TestAuthUpdateSessions\"}"
        }
      );  
      logger.info(() -> String.format("%s %s", this, "Updated session " + sessionId + "."));
    }
    logger.finer(() -> String.format("RETURN %s", this));
  }
}

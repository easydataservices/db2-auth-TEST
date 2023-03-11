package com.easydataservices.open.test;

import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.TimeZone;
import java.util.logging.Logger;
import com.easydataservices.open.auth.AuthAttributesDao;
import com.easydataservices.open.auth.AuthSessionDao;
import com.easydataservices.open.auth.StoreSession;
import com.easydataservices.open.auth.StoreAttribute;
import com.easydataservices.open.test.TestAuthBootstrap;
import com.easydataservices.open.test.TestAuthPayload;

/**
 * AUTH Service test payload class for retrieving sessions and their attributes.
 *
 * @author jeremy.rickard@easydataservices.com
 */
public class TestAuthGetSessions extends TestAuthPayload {
  private static final String className = TestAuthGetSessions.class.getName();
  private static final Logger logger = Logger.getLogger(className);
  private AuthSessionDao authSessionDao;
  private AuthAttributesDao authAttributesDao;
  private String sessionIdPrefix;


  public void init(TestAuthBootstrap bootstrap) throws Exception {
    logger.finer(() -> String.format("ENTRY %s %s", this, bootstrap));
    authSessionDao = new AuthSessionDao(bootstrap.getConnection(), bootstrap.getDbSchema());
    authAttributesDao = new AuthAttributesDao(bootstrap.getConnection(), bootstrap.getDbSchema());
    sessionIdPrefix = bootstrap.getPayloadPrefix1() + "_";
    logger.finer(() -> String.format("RETURN %s", this));
  }

  public void payload(int rangeValue, int iteration) throws Exception {
    final long offsetSeconds = (TimeZone.getDefault().getRawOffset() / 1000);

    logger.finer(() -> String.format("ENTRY %s %s %s", this, rangeValue, iteration));
    String sessionId = sessionIdPrefix + rangeValue;
    StoreSession session = authSessionDao.getSession(sessionId);
    if (session != null) {
      String sessionInfo = "Session " + session.getSessionId() + " retrieved."
        + "\nsessionId: " + session.getSessionId()
        + "\ncreatedTime: " + session.getCreatedTime()
        + "\nlastAccessedTime: " + session.getLastAccessedTime()
        + "\nlastAuthenticatedTime: " + session.getLastAuthenticatedTime()
        + "\nmaxIdleMinutes: " + session.getMaxIdleMinutes()
        + "\nmaxAuthenticationMinutes: " + session.getMaxAuthenticationMinutes()
        + "\nexpiryTime: " + session.getExpiryTime()
        + "\nauthName: " + session.getAuthName()
        + "\npropertiesJson: " + session.getPropertiesJson()
        + "\nisAuthenticated: " + session.isAuthenticated()
        + "\nisExpired: " + session.isExpired()
        + "\nattributeGenerationId: " + session.getAttributeGenerationId();
      List<StoreAttribute> attributeList = authAttributesDao.getAttributes(sessionId, 0);
      for (StoreAttribute attribute : attributeList) {
        sessionInfo = sessionInfo + "\n\n  attributeName: " + attribute.getAttributeName()
          + "\n  generationId: " + attribute.getGenerationId()
          + "\n  object.length: " + attribute.getObject().toString().length();
      }
      final String text = "Session " + session.getSessionId() + " retrieved." + sessionInfo;
      logger.info(() -> String.format("%s %s", this, "Session " + sessionId + " retrieved." + text));
    }
    else {
      logger.info(() -> String.format("%s %s", this, "Session " + sessionId + " does not exist."));
    }
    logger.finer(() -> String.format("RETURN %s", this));
  }
}

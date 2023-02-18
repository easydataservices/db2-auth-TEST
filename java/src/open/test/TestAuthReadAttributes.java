package com.easydataservices.open.test;

import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.TimeZone;
import com.easydataservices.open.auth.AuthAttributesDao;
import com.easydataservices.open.auth.AuthSessionDao;
import com.easydataservices.open.auth.StoreSession;
import com.easydataservices.open.auth.StoreAttribute;
import com.easydataservices.open.test.TestAuthBootstrap;
import com.easydataservices.open.test.TestAuthPayload;

/**
 * AUTH Service test payload class for testing the ATTRIBUTES.READ_ATTRIBUTES procedure.
 *
 * @author jeremy.rickard@easydataservices.com
 */
public class TestAuthReadAttributes extends TestAuthPayload {
  private AuthSessionDao authSessionDao;
  private AuthAttributesDao authAttributesDao;
  private String sessionId;

  public void init(TestAuthBootstrap bootstrap) throws Exception {
    authSessionDao = new AuthSessionDao(bootstrap.getConnection(), bootstrap.getDbSchema());
    authAttributesDao = new AuthAttributesDao(bootstrap.getConnection(), bootstrap.getDbSchema());
    sessionId = bootstrap.getPayloadUniqueId();
  }

  public void payload(int iteration) throws Exception {
    final long offsetSeconds = (TimeZone.getDefault().getRawOffset() / 1000);

    StoreSession session = authSessionDao.getSession(sessionId);
    if (session != null) {
      System.out.println("TIME NOW: " + Instant.now().atOffset(ZoneOffset.ofHours(0)));  
      System.out.println("sessionId: " + session.getSessionId());
      System.out.println("createdTime: " + session.getCreatedTime());  
      System.out.println("lastAccessedTime: " + session.getLastAccessedTime());  
      System.out.println("maxIdleMinutes: " + session.getMaxIdleMinutes());  
      System.out.println("maxAuthenticationMinutes: " + session.getMaxAuthenticationMinutes());  
      System.out.println("expiryTime: " + session.getExpiryTime());
      System.out.println("authName: " + session.getAuthName());
      System.out.println("propertiesJson: " + session.getPropertiesJson());
      System.out.println("isAuthenticated: " + session.isAuthenticated());
      System.out.println("isExpired: " + session.isExpired());
      System.out.println("attributeGenerationId: " + session.getAttributeGenerationId());
    }
    List<StoreAttribute> attributeList = authAttributesDao.getAttributes(sessionId, 0);
    for (StoreAttribute attribute : attributeList) {
      System.out.println("attributeName: " + attribute.getAttributeName());
      Object object = attribute.getObject();
      System.out.println("object.length: " + object.toString().length());
    }
  }
}
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0">
    
    <xsl:output method="html" encoding="UTF-8" indent="yes" />
    
    <xsl:template match="/locations">
        <select name="locations" id="locations_dropdown">
            <option value="1">Global</option>
            <xsl:apply-templates select="location" />
        </select>
    </xsl:template>
    
    <xsl:template match="location">
        <option>
            <xsl:attribute name="value"><xsl:value-of select="woeid"/></xsl:attribute>
            <xsl:value-of select="name"/>
        </option>
    </xsl:template>
    
</xsl:stylesheet>
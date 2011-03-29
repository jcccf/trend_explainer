<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:a="http://www.w3.org/2005/Atom"
    xmlns:tr="http://my.superdupertren.ds"
    xmlns:tw="http://api.twitter.com"
    xmlns:wi="http://www.wikipedia.org"
    xmlns:bi="http://www.bing.com">
    
    <xsl:output method="html" encoding="UTF-8" indent="yes" />
    
    <!--Base-->
    <xsl:template match="/">
        <xsl:apply-templates select="a:entry" />
    </xsl:template>
    
    <!--Parse Atom entry-->
    <xsl:template match="a:entry">
        <h1><xsl:value-of select="a:title"/></h1>
        <h3>Retrieved on <xsl:value-of select="a:updated"/></h3>
        <xsl:apply-templates select="tr:trends"/>
    </xsl:template>
    
    <!--Parse Trendy object-->
    <xsl:template match="tr:trends">
        <h3>Trends that are <xsl:value-of select="@location"/></h3>
        <xsl:apply-templates select="tw:trend" />
    </xsl:template>
    
    <!--Parse Trendy trend-->
    <xsl:template match="tw:trend">
        <div class="trend">
        <h2><xsl:value-of select="@topic"/></h2>
        <b>Bing says:</b><xsl:value-of select="bi:top_result" /><br />
        <b>Wikipedia says:</b><xsl:value-of select="wi:abstract" /><br />
        <b>You say:</b><xsl:value-of select="tr:user_comment" />
        </div>
    </xsl:template>
    
</xsl:stylesheet>
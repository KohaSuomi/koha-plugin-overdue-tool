<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:output method="html" indent="yes"/>

    <xsl:template match="/">
        <div class="header">
            <div class="sender">
                <div class="library">
                    <ul class="info">
                        <li><xsl:value-of select="//SellerOrganisationName"/></li>
                        <li><xsl:value-of select="//SellerStreetName"/></li>
                        <li><xsl:value-of select="//SellerPostCodeIdentifier"/> <xsl:value-of select="//SellerTownName"/></li>
                        <li><xsl:value-of select="//SellerPartyIdentifier"/></li>
                    </ul>
                </div>
                <div class="billheader">
                    <ul class="info">
                        <li><strong>Lasku</strong></li>
                        <li>Laskun numero: <xsl:value-of select="//InvoiceNumber"/></li>
                        <li>Päiväys: <xsl:value-of select="//MessageDetails/MessageTimeStamp"/></li>
                        <li>Viitenumero: <xsl:value-of select="//EpiRemittanceInfoIdentifier"/></li>
                        <li>Eräpäivä: <xsl:value-of select="//InvoiceDueDate"/></li>
                    </ul>
                </div>
            </div>
        </div>

        <div class="recipient">
            <ul class="info">
                <li><xsl:value-of select="//BuyerOrganisationName"/></li>
                <li><xsl:value-of select="//BuyerStreetName"/></li>
                <li><xsl:value-of select="//BuyerPostCodeIdentifier"/> <xsl:value-of select="//BuyerTownName"/></li>
            </ul>
        </div>

        <div class="content">
            <p><strong>Lainaajan: </strong> <xsl:value-of select="//BuyerContactPersonName"/></p>
            <table class="table">
                <thead>
                    <tr>
                        <th>Eräpäivä</th>
                        <th>Nimeke</th>
                        <th>Nidenumero</th>
                        <th>Hinta</th>
                    </tr>
                </thead>
                <tbody>
                    <xsl:for-each select="//InvoiceRow">
                        <tr>
                            <td><xsl:value-of select="RowIdentifierDate"/></td>
                            <td><xsl:value-of select="ArticleName"/></td>
                            <td>
                                <xsl:value-of select="ArticleIdentifier"/><br/>
                            </td>
                            <td>
                                <xsl:value-of select="UnitPriceNetAmount"/>€<br/>
                            </td>
                        </tr>
                    </xsl:for-each>
                </tbody>
            </table>
        </div>

        <div class="summary">
            <ul class="info">
                <li>Viitenumero: <xsl:value-of select="//EpiRemittanceInfoIdentifier"/></li>
                <li>Yhteensä: <xsl:value-of select="//InvoiceTotalVatIncludedAmount"/>€</li>
                <li>Eräpäivä: <xsl:value-of select="//InvoiceDueDate"/></li>
            </ul>
        </div>

        <div class="footer">
            <div class="library">
                <ul class="info">
                    <li><xsl:value-of select="//SellerOrganisationName"/></li>
                    <li><xsl:value-of select="//SellerStreetName"/></li>
                    <li><xsl:value-of select="//SellerPostCodeIdentifier"/> <xsl:value-of select="//SellerTownName"/></li>
                    <li><xsl:value-of select="//SellerPartyIdentifier"/></li>
                </ul>
            </div>
        </div>
    </xsl:template>
</xsl:stylesheet>
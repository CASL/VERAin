<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:xs="http://www.w3.org/2001/XMLSchema"
		xmlns:exslt="http://exslt.org/common"
		xmlns:msxsl="urn:schemas-microsoft-com:xslt"
		exclude-result-prefixes="exslt msxsl"
>

<!--
    version 9.C:07/27/2012:463:13911:Srdjan Simunovic
    simunovics@ornl.gov
    http://thyme.ornl.gov/simunovics
    XSLT for ParameterList reactor file
 -->

<msxsl:script language="JScript" implements-prefix="exslt">
 this['node-set'] =  function (x) {
  return x;
  }
</msxsl:script>

<xsl:output method="html" 
    doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"
    doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN" />

<!-- SSMOD: Note to self, change tags to xsl elements -->

<xsl:template match="/">
  <xsl:element name="html">
    <xsl:element name="head">
      <xsl:element name="title">
	<xsl:value-of select="ParameterList/Parameter[@name='case_id']/@value" />
      </xsl:element>

      <!-- CSS 3, IE will not work -->

      <style type="text/css">
	table, td
	{
	border-color: #600;
	border-style: dotted;
	}
	table
	{
	border-width: 0 0 1px 1px;
	border-spacing: 0;
	border-collapse: collapse;
	}
	td
	{
	margin: 0;
	padding: 4px;
	border-width: 1px 1px 0 0;
	width: 20px;
	text-align: center;
	white-space:nowrap;
	}
	tr:nth-child(even) td:nth-child(odd)
	{
	background-color: #E0FFFF;
	}
	tr:nth-child(odd) td:nth-child(even)
	{
	background-color: #E0FFFF;
	}
      </style>
    </xsl:element>

    <xsl:element name="body">
<!-- comment from here to -A1- if you want the exact hierarchy -->
<!--
      <xsl:element name="p">
	<strong><xsl:value-of select="ParameterList/@name" /></strong>
      </xsl:element>
      <xsl:element name="ul">
	<xsl:apply-templates select="ParameterList/Parameter" />
      </xsl:element>
      <xsl:apply-templates select="ParameterList/ParameterList" />
-->
<!-- -A1- -->

<!-- uncomment from here to -A2- if you want the exact hierarchy -->
    <xsl:apply-templates select="*"/>
<!-- -A2- -->
    </xsl:element>
  </xsl:element>
</xsl:template>

<xsl:template match="ParameterList">
  <xsl:element name="p">
    <xsl:element name="strong">
      <xsl:value-of select="@name" />
    </xsl:element>
  </xsl:element>
  <xsl:element name="ul">
    <xsl:apply-templates select="Parameter" />
  </xsl:element>
  <xsl:element name="ul">
    <xsl:apply-templates select="ParameterList" />
  </xsl:element>
</xsl:template>

<xsl:template match="Parameter">

<!-- SSMOD: Modify to explicit checking of each keyword -->

  <xsl:choose>
    <xsl:when test="@name = 'shape' or @name = 'dancoff_map' or @name = 'cell_map'">
      <xsl:variable name="num_pins">
	<xsl:choose>
	  <xsl:when test="../../../Parameter[@name = 'num_pins']">
	    <xsl:value-of select="../../../Parameter[@name = 'num_pins']/@value" />
	  </xsl:when>
	  <xsl:when test="../Parameter[@name = 'num_pins']">
	    <xsl:value-of select="../Parameter[@name = 'num_pins']/@value" />
	  </xsl:when>
	  <xsl:when test="../Parameter[@name = 'core_size']">
	    <xsl:value-of select="../Parameter[@name = 'core_size']/@value" />
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:value-of select="0" />
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:variable>
      <xsl:variable name="map" select="@value" />

      <xsl:if test="$num_pins > 0">
	<xsl:element name="li">
	  <xsl:element name="p">
	    <xsl:value-of select="@name" /> = 
	    <xsl:call-template name="make_map">
	      <xsl:with-param name="num_pins">
		<xsl:value-of select="$num_pins" />
	      </xsl:with-param>
	      <xsl:with-param name="map">
		<xsl:value-of select="$map" />
	      </xsl:with-param>
	    </xsl:call-template>
	  </xsl:element>
	</xsl:element>
      </xsl:if>
    </xsl:when>

    <!-- maps over templates -->

    <xsl:when test="@name = 'insert_map' or @name = 'assm_map' or @name = 'crd_map' or @name = 'det_map' or @name = 'crd_bank' or @name = 'rotate_map'">
      <xsl:variable name="num_pins" select="../Parameter[@name = 'core_size']/@value" />
      <xsl:variable name="shape"    select="../Parameter[@name = 'shape']/@value" />
      <xsl:variable name="map"      select="@value" />

      <xsl:if test="$num_pins > 0">
	<xsl:element name="li">
	  <xsl:element name="p">
	    <xsl:value-of select="@name" /> = 
	    <xsl:call-template name="make_core_map">
	      <xsl:with-param name="num_pins">
		<xsl:value-of select="$num_pins" />
	      </xsl:with-param>
	      <xsl:with-param name="shape">
		<xsl:value-of select="$shape" />
	      </xsl:with-param>
	      <xsl:with-param name="map">
		<xsl:value-of select="$map" />
	      </xsl:with-param>
	    </xsl:call-template>
	  </xsl:element>
	</xsl:element>
      </xsl:if>
    </xsl:when>

    <xsl:when test="@name = 'tinlet_dist' or @name = 'flow_dist' or @name = 'shuffle_label'">
      <xsl:variable name="num_pins" select="../../../ParameterList[@name = 'CORE']/Parameter[@name = 'core_size']/@value" />
      <xsl:variable name="shape"    select="../../../ParameterList[@name = 'CORE']/Parameter[@name = 'shape']/@value" />
      <xsl:variable name="map"      select="@value" />

      <xsl:if test="$num_pins > 0">
	<xsl:element name="li">
	  <xsl:element name="p">
	    <xsl:value-of select="@name" /> = 
	    <xsl:call-template name="make_core_map">
	      <xsl:with-param name="num_pins">
		<xsl:value-of select="$num_pins" />
	      </xsl:with-param>
	      <xsl:with-param name="shape">
		<xsl:value-of select="$shape" />
	      </xsl:with-param>
	      <xsl:with-param name="map">
		<xsl:value-of select="$map" />
	      </xsl:with-param>
	    </xsl:call-template>
	  </xsl:element>
	</xsl:element>
      </xsl:if>
    </xsl:when>

    <!-- regular arrays -->

    <xsl:when test="not(@name = 'shape' or @name = 'dancoff_map' or @name = 'cell_map' or @name = 'insert_map' or @name = 'assm_map' or @name = 'crd_map' or @name = 'det_map' or @name = 'crd_bank') and starts-with(@type,'Array')">

      <xsl:variable name="var_ma"    select="translate(@value,'\{\}','')" />
      <xsl:variable name="map_array">
	<xsl:call-template name="tokenize">
	  <xsl:with-param name="string"     select="$var_ma"/>
	  <xsl:with-param name="delimiters" select="','"/>
	</xsl:call-template>
      </xsl:variable>

      <xsl:element name="li">
	<xsl:element name="p">
	  <xsl:value-of select="@name" /> = 
	  <table>
	    <tr>
	      <xsl:for-each select="exslt:node-set($map_array)/token">
		<td>
		  <xsl:value-of select="."/>
		</td>
	      </xsl:for-each>
	    </tr>
	  </table>
	</xsl:element>
      </xsl:element>
    </xsl:when>

    <!-- scalars -->

    <xsl:otherwise>
      <xsl:element name="li">
	<xsl:element name="p">
	  <xsl:element name="i">
	    <xsl:value-of select="@name" />
	  </xsl:element> = <xsl:value-of select="@value" />
	</xsl:element>
      </xsl:element>
    </xsl:otherwise>
  </xsl:choose>

</xsl:template>

<!-- vanilla map -->

<xsl:template name="make_map">
  <xsl:param name="num_pins"></xsl:param>
  <xsl:param name="map"></xsl:param>

  <xsl:variable name="var_ma"    select="translate($map,'\{\}','')" />
  <xsl:variable name="map_array">
    <xsl:call-template name="tokenize">
      <xsl:with-param name="string"     select="$var_ma"/>
      <xsl:with-param name="delimiters" select="','"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:call-template name="disp_nrow">
    <xsl:with-param name="dat"     select="exslt:node-set($map_array)/token" />
    <xsl:with-param name="num_pins" select="$num_pins" />
  </xsl:call-template>

</xsl:template>

<!-- map of maps -->

<xsl:template name="make_core_map">
  <xsl:param name="num_pins"></xsl:param>
  <xsl:param name="shape"></xsl:param>
  <xsl:param name="map"></xsl:param>

  <xsl:variable name="var_sh"    select="translate($shape,'\{\}','')" />
  <xsl:variable name="sh_array">
    <xsl:call-template name="tokenize">
      <xsl:with-param name="string"     select="$var_sh"/>
      <xsl:with-param name="delimiters" select="','"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="shape_array"  select="exslt:node-set($sh_array)/token" />

  <xsl:variable name="var_ma"    select="translate($map,'\{\}','')" />
  <xsl:variable name="map_array">
    <xsl:call-template name="tokenize">
      <xsl:with-param name="string"     select="$var_ma"/>
      <xsl:with-param name="delimiters" select="','"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="map_map">
    <xsl:for-each select="$shape_array">
      <xsl:variable name="ips" select="position()"/>
      <xsl:variable name="sli" select="$shape_array[position() &gt;=  1 and position() &lt;= $ips]"/>
      <xsl:variable name="smi" select="sum($sli)" />

      <xsl:variable name="smv" select="exslt:node-set($map_array)/token[$smi]"/>

      <xsl:element name="ent">
	<xsl:choose>
	  <xsl:when test="number(.) = 0">
	    <xsl:value-of select="''" />
	  </xsl:when>
	  <xsl:otherwise>
	    <xsl:value-of select="$smv" />
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:element>

    </xsl:for-each>
  </xsl:variable>

  <xsl:call-template name="disp_nrow">
    <xsl:with-param name="dat"     select="exslt:node-set($map_map)/ent" />
    <xsl:with-param name="num_pins" select="$num_pins" />
  </xsl:call-template>

</xsl:template>

<!-- cookbook stuff -->

<xsl:template name="tokenize">
  <xsl:param name="string" select="''" />
  <xsl:param name="delimiters" select="' &#x9;&#xA;'" />
  <xsl:choose>
    <xsl:when test="not($string)" />
    <xsl:when test="not($delimiters)">
      <xsl:call-template name="_tokenize-characters">
        <xsl:with-param name="string" select="$string" />
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="_tokenize-delimiters">
        <xsl:with-param name="string" select="$string" />
        <xsl:with-param name="delimiters" select="$delimiters" />
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!--
<xsl:template name="_tokenize-characters">
  <xsl:param name="string" />
  <xsl:if test="$string">
    <token><xsl:value-of select="substring($string, 1, 1)" /></token>
    <xsl:call-template name="_tokenize-characters">
      <xsl:with-param name="string" select="substring($string, 2)" />
    </xsl:call-template>
  </xsl:if>
</xsl:template>
-->

<xsl:template name="_tokenize-characters">
  <xsl:param name="string" />
  <xsl:param name="len" select="string-length($string)"/>
  <xsl:choose>
	  <xsl:when test="$len = 1">
      <token><xsl:value-of select="$string"/></token>
	  </xsl:when>
	  <xsl:otherwise>
      <xsl:call-template name="_tokenize-characters">
        <xsl:with-param name="string" select="substring($string, 1, floor($len div 2))" />
        <xsl:with-param name="len" select="floor($len div 2)"/>
      </xsl:call-template>
      <xsl:call-template name="_tokenize-characters">
        <xsl:with-param name="string" select="substring($string, floor($len div 2) + 1)" />
        <xsl:with-param name="len" select="ceiling($len div 2)"/>
      </xsl:call-template>
	  </xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template name="_tokenize-delimiters">
  <xsl:param name="string" />
  <xsl:param name="delimiters" />
  <xsl:param name="last-delimit"/> 
  <xsl:variable name="delimiter" select="substring($delimiters, 1, 1)" />
  <xsl:choose>
    <xsl:when test="not($delimiter)">
      <token><xsl:value-of select="$string"/></token>
    </xsl:when>
    <xsl:when test="contains($string, $delimiter)">
      <xsl:if test="not(starts-with($string, $delimiter))">
        <xsl:call-template name="_tokenize-delimiters">
          <xsl:with-param name="string" select="substring-before($string, $delimiter)" />
          <xsl:with-param name="delimiters" select="substring($delimiters, 2)" />
        </xsl:call-template>
      </xsl:if>
      <xsl:call-template name="_tokenize-delimiters">
        <xsl:with-param name="string" select="substring-after($string, $delimiter)" />
        <xsl:with-param name="delimiters" select="$delimiters" />
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="_tokenize-delimiters">
        <xsl:with-param name="string" select="$string" />
        <xsl:with-param name="delimiters" select="substring($delimiters, 2)" />
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!--
    sum recursion
    SSMOD: remember error in using select in variable name tag
-->

<xsl:template name="sum">
  <xsl:param name="nodes" select="/.."/>
  <xsl:param name="result" select="'0'"/>
  <xsl:choose>
    <xsl:when test="not($nodes)">
      <xsl:value-of select="$result"/>
    </xsl:when>
    <xsl:otherwise>
      <!--
	  call or apply template that will determine value of node
	  unless the node is literally the value to be summed
	-->
      <xsl:variable name="value">
	<xsl:value-of select="$nodes[1]" />
	<!--
            <xsl:call-template name="some-function-of-a-node">
	      <xsl:with-param name="node" select="$nodes[1]"/>
            </xsl:call-template>
            -->
      </xsl:variable>
      <xsl:call-template name="sum">
        <xsl:with-param name="nodes" select="$nodes[position() != 1]"/>
        <xsl:with-param name="result" select="$result + $value"/>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="disp_nrow">
  <xsl:param name="dat"></xsl:param>
  <xsl:param name="num_pins"></xsl:param>

  <xsl:variable name="idx">
    <xsl:for-each select="$dat">
      <xsl:element name="val">
	<xsl:attribute name="row">
	  <xsl:value-of select="ceiling(position() div $num_pins)" />
	</xsl:attribute>
	<xsl:value-of select="." />
      </xsl:element>
    </xsl:for-each>
  </xsl:variable>

  <!-- create number sequence -->

  <xsl:variable name="row_list">
    <xsl:call-template name="number.options">
      <xsl:with-param name="i" select="number(1)" />
      <xsl:with-param name="count"  select="number($num_pins)" />
    </xsl:call-template>
  </xsl:variable>


  <xsl:element name="table">

    <xsl:for-each select="exslt:node-set($row_list)/num">
      <xsl:element name="tr">
	<xsl:for-each select="exslt:node-set($idx)/val[@row = current()]">
	  <xsl:element name="td">
	    <xsl:value-of select="." />
	  </xsl:element>
	</xsl:for-each>  
      </xsl:element>
    </xsl:for-each>  
    
  </xsl:element>

</xsl:template>

<!-- create number sequence i to count -->

<xsl:template name="number.options">
  <xsl:param name="i" />
  <xsl:param name="count" />
  <xsl:if test="$i &lt;= $count">
    <xsl:element name="num">
      <xsl:value-of select="$i"/>
    </xsl:element>
  </xsl:if>
  <xsl:if test="$i &lt;= $count">
    <xsl:call-template name="number.options">
      <xsl:with-param name="i" select="$i + 1"/>
      <xsl:with-param name="count" select="$count"/>
    </xsl:call-template>
  </xsl:if>
</xsl:template>


</xsl:stylesheet>

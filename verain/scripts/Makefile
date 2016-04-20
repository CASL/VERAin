# Precompilation of the templates to speed up the parsing
# The resulting parser is r.exec
#
# mod 20160420
# Srdjan Simunovic
# simunovics@ornl.gov

INDIR := Templates
OUTDIR := pyml

yml_files := $(wildcard ${INDIR}/*.yml)
pyml_files := $(subst ${INDIR}/,${OUTDIR}/,${yml_files:.yml=.pyml})

.PHONY: all clean

all : exec

clean :
	rm -f ${pyml_files} r.exec

${OUTDIR}/%.pyml : ${INDIR}/%.yml
	utils/yml2pl.pl $< $@

exec: ${pyml_files} react2xml_template
	utils/ple.pl react2xml_template r.exec
	chmod +x ./r.exec

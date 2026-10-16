const axios= require('axios');
module.exports = async function form_req(router, {services, exceptions}) {
    const { ItemsService } = services;
    const errors = await import('@directus/errors').then((errors) => (errors));

    router.get('/new', (_req, res, next) => {
        if (!_req.accountability.user) {
            const ForbiddenError = errors.createError('FORBIDDEN', "You don't have permissions to see this.", 403);
            throw new ForbiddenError();
        }
        // Template code
        const code = _req.query["code"] ? _req.query["code"] : '';
        // console.log(code)
        const headerService = new ItemsService('Template_header', { schema: _req.schema, accountability: _req.accountability });
        headerService.readByQuery({
            filter:{
                'template': code
            },
            sort: ['id'],
            fields: ['*', 'template_type.*']
        }).then(
            (results) => {
                const changed_result = []
                results.map((item) => {
                    // console.log(item)
                    let formkit_code = { ...item.template_type.code };
                    try {
                        formkit_code["name"] = item.name;
                        formkit_code["label"] = item.label;
                        formkit_code["help"] = item.help;
                        formkit_code["validation"] = item.validation;
                    } catch (e) {

                    }

                    // Here is formkit code overwrite from database
                    switch (item.template_type.name) {
                        case 'checkbox':
                            try {
                                formkit_code["id"] = item.name + item.id;
                            } catch (e) {

                            }
                            break;
                        case 'select':
                            try {
                                formkit_code["options"] = item.options;
                            } catch (e) {

                            }
                            break;
                        default: break;
                    }
                    changed_result.push(formkit_code)
                })
                return res.json(changed_result)
            }
        ).catch((error) => {
            const ServiceUnavailableException = errors.createError('Service unavailable', error.message, 403);
            return next(new ServiceUnavailableException(error.message));
        });
    });

    router.get('/update', (_req, res, next) => {
        if (!_req.accountability.user) {
            const ForbiddenError = errors.createError('FORBIDDEN', "You don't have permissions to see this.", 403);
            throw new ForbiddenError();
        }
        // Template code
        const code = _req.query["code"] ? _req.query["code"] : '';
        const headerService = new ItemsService('Template_value', { schema: _req.schema, accountability: _req.accountability });
        headerService.readByQuery({
            filter:{
                'code': code
            },
            sort: ['id'],
            fields: ['*', 'header.*', 'header.template_type.*']
        }).then(
            (results) => {
                const changed_result = []
                results.map((item) => {
                    // console.log(item)
                    let formkit_code = { ...item.header.template_type.code };
                    try {
                        formkit_code["name"] = item.header.name;
                        formkit_code["label"] = item.header.label;
                        formkit_code["help"] = item.header.help;
                        formkit_code["validation"] = item.header.validation;
                        formkit_code["value"] = item.value
                    } catch (e) {

                    }

                    // Here is formkit code overwrite from database
                    switch (item.header.template_type.name) {
                        case 'checkbox':
                            try {
                                formkit_code["id"] = item.header.name + item.header.id;
                            } catch (e) {

                            }
                            break;
                        case 'select':
                            try {
                                formkit_code["options"] = item.header.options;
                            } catch (e) {

                            }
                            break;
                        default: break;
                    }
                    changed_result.push(formkit_code)
                })
                return res.json(changed_result)
            }
        ).catch((error) => {
            const ServiceUnavailableException = errors.createError('Service unavailable', error.message, 403);
            return next(new ServiceUnavailableException(error.message));
        });
    });

}
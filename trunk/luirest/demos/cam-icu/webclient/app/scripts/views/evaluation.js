/*global define*/

define([
    'jquery',
    'underscore',
    'backbone',
    'text!templates/evaluation.html',
    'stickitform',
    'validation'

], function ($, _, Backbone, html, StickitForm, Validation) {
    'use strict';

    var EvaluationView = Backbone.View.extend({
        html: html,

        bindings: function(){
            var bindings = StickitForm.getBindings({
                attributes: ['date', 'rass', 'deliriumid', 'sedation', 'ventilationid', 'shiftid'],
                defaults: {
                    setOptions: {
                        validate: true
                    }
                },
                extend: {
                    date:{
                      onGet: function(val){
                          return fromOADate(val).toLocaleDateString();
                      }
                    },
                    sedation: {
                      onGet: function (val) {
                          if (_.isArray(val)){
                              return val.map(function (item) {
                                  return item.toString();
                              })
                          };
                      },
                      onSet: function (val) {
                          if (_.isArray){
                            return val.map(function (item) {
                                 return parseInt(item);
                              });
                          } else
                           return parseInt(val);
                      }
                    },
                    shiftid: {
                        selectOptions:{
                            collection: [
                                {name: 'Manhã', value: 1},
                                {name: 'Tarde', value: 2},
                                {name: 'Noite', value: 3}
                            ],
                            labelPath: 'name',
                            defaultOption: {label: 'Selecione...', value: null}
                        }
                    },
                    deliriumid: {
                        selectOptions:{
                            collection: [
                                {name: 'Hipoativo', value: 1},
                                {name: 'Misto', value: 2},
                                {name: 'Hiperativo', value: 3},
                                {name: 'Não', value: 4},
                                {name: 'Não Avaliado', value: 5},
                                {name: 'NC', value: 9}
                            ],
                            labelPath: 'name',
                            defaultOption: {label: 'Selecione uma opção...', value: null}
                        }
                    },
                    ventilationid: {
                        selectOptions:{
                            collection: function() {
                               return [
                                    {name: 'Mecânica', value: 1},
                                    {name: 'Espontânea', value: 2},
                                    {name: 'VNI', value: 3}, {name: 'NC', value: 9}
                                ];
                            },
                            labelPath: 'name',
                            defaultOption: {label: 'Selecione uma opção...', value: null}
                        }
                    }
                }
            });
            _.extend(bindings, {
                '.title-el':{
                    observe: 'id',
                    onGet: function (val) {
                        var title = (this.model.isNew()) ? 'Adicionar': 'Editar';
                        title += ' Avaliação';
                        return title;
                    }
                }
            })

            return bindings;
        },


        patientBindings: {
          '.name-el':'name'
        },

        tagName: 'div',

        id: '',

        className: '',

        events: {
            'click button.save-model': 'saveModel',
            'click button.cancel': 'cancel'
        },

        initialize: function () {
            Validation.bind(this);
        },

        render: function () {
            this.$el.html(this.html);
            this.stickit();
            this.stickit(this.collection.patient, this.patientBindings);
            return this;
        },
        remove: function () {
            Validation.unbind(this);
            return Backbone.View.prototype.remove.apply(this, arguments);
        },
        cancel: function () {
            //window.history.back();
            app.mainRouter.navigate('#patients/' + this.collection.patient.get('id') + '/evaluations', true)
        },

        saveModel: function () {
            if (!this.model.isValid(true)){
                this.$('.alert-danger').removeClass('hidden').html('Um ou mais campos contem dados inválidos');
                return;
            }
            var self = this;
            var isNew = this.model.isNew();
            if (isNew){
                this.model.collection = this.collection;
            };
            this.model.save({}, {
                success: function(model, response, options){
                    console.log('Evaluation saved', model, response, options);
                    if (isNew) {
                        self.collection.add(model);
                    };
                    app.mainRouter.navigate('#patients/' + model.get('patientid') + '/evaluations', true);
                },
                error: function(model, response, options){
                    var msg = '--';
                    console.log('Error saving evaluation', model, response, options);
                    if ((response.responseJSON) && (response.responseJSON.message)){
                        msg = response.responseJSON.message;
                    }
                    this.$('.alert-danger').removeClass('hidden').html('Erro ao salvar dados');
                }
            })
        }
    });

    return EvaluationView;
});
